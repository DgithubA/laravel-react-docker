# Stage 1: Build environment and Composer dependencies
FROM php:8.3-fpm AS builder

# user default php.ini production for builder stage
# RUN mv "$PHP_INI_DIR/php.ini-production" "$PHP_INI_DIR/php.ini"

# install composer
RUN curl -sS https://getcomposer.org/installer | php -- --install-dir=/usr/local/bin --filename=composer

# Install system dependencies and PHP extensions required for Laravel + MySQL/PostgreSQL support
# Some dependencies are required for PHP extensions only in the build stage
RUN apt-get update && apt-get install -y --no-install-recommends \
    curl \
    unzip \
    libpq-dev \
    libonig-dev \
    libssl-dev \
    libxml2-dev \
    libcurl4-openssl-dev \
    libicu-dev \
    libzip-dev \
    && docker-php-ext-install -j$(nproc) \
    pdo_mysql \
    pdo_pgsql \
    pgsql \
    opcache \
    intl \
    zip \
    bcmath \
    soap \
    && pecl install redis \
    && docker-php-ext-enable redis \
    && docker-php-ext-install zip pcntl \
    && apt-get autoremove -y && apt-get clean && rm -rf /var/lib/apt/lists/* /tmp/* /var/tmp/*


#### install project specific extentions/packages (composer check-platform-reqs) ####
## RUN pecl install --configureoptions='with-mongodb-system-libs="no" enable-mongodb-developer-flags="no"' mongodb && docker-php-ext-enable mongodb
# RUN apt update && apt install -y --no-install-recommends libpng-dev
# RUN docker-php-ext-install ftp gd sockets

# Set the working directory inside the container
WORKDIR /var/www

# Copy composer required file for install dependencies
COPY composer.json composer.lock /var/www/


#install octane of not exist in composer.json (this command change used octane version in composer.json If defined.)
# RUN composer require laravel/octane --no-update --no-interaction --no-progress --prefer-dist --no-scripts

# Install dependencies
RUN composer install --no-dev --no-autoloader --no-interaction --no-progress --prefer-dist --no-scripts --no-ansi

# Copy the entire Laravel application code into the container
COPY --chown=www-data:www-data . /var/www/

# make required folders
RUN mkdir -p bootstrap/cache

# dump autoload after install dependencies
RUN composer dump-autoload --optimize --no-interaction --no-ansi

# in some project required to publish package assets to public
RUN composer run post-update-cmd --no-interaction --no-ansi

# install octane server
ARG OCTANE_SERVER="swoole"
RUN php artisan octane:install --server=${OCTANE_SERVER:-swoole} --no-ansi --no-interaction



################################ Stage 2: Production environment ####################################
FROM php:8.3-fpm AS runner

# Latest releases available at https://github.com/aptible/supercronic/releases
ENV SUPERCRONIC_URL=https://github.com/aptible/supercronic/releases/download/v0.2.33/supercronic-linux-amd64 \
    SUPERCRONIC_SHA1SUM=71b0d58cc53f6bd72cf2f293e09e294b79c666d8 \
    SUPERCRONIC=supercronic-linux-amd64

RUN curl -fsSLO "$SUPERCRONIC_URL" \
&& echo "${SUPERCRONIC_SHA1SUM}  ${SUPERCRONIC}" | sha1sum -c - \
&& chmod +x "$SUPERCRONIC" \
&& mv "$SUPERCRONIC" "/usr/local/bin/${SUPERCRONIC}" \
&& ln -s "/usr/local/bin/${SUPERCRONIC}" /usr/bin/supercronic

# Install client libraries required for php extensions in runtime
RUN apt-get update && apt-get install -y --no-install-recommends \
    supervisor \
    libpq-dev \
    libicu-dev \
    libzip-dev \
    && apt-get autoremove -y && apt-get clean && rm -rf /var/lib/apt/lists/* /tmp/* /var/tmp/*


#### Install Specific client libraries required for php extensions in runtime (composer check-platform-reqs) ####
# RUN apt update && apt install -y --no-install-recommends libpng-dev
# RUN pecl install openswoole && docker-php-ext-enable openswoole



#### Use the default production configuration for PHP runtime arguments ####
RUN mv "$PHP_INI_DIR/php.ini-production" "$PHP_INI_DIR/php.ini"
#### or copy custom php.ini here ####
# COPY docker/configs/php/php.ini $PHP_INI_DIR/php.ini



# Copy PHP extensions and libraries from the builder stage
COPY --from=builder /usr/local/lib/php/extensions/ /usr/local/lib/php/extensions/
COPY --from=builder /usr/local/etc/php/conf.d/ /usr/local/etc/php/conf.d/
COPY --from=builder /usr/local/bin/docker-php-ext-* /usr/local/bin/



#### copy config files ####
COPY --chown=www-data:www-data docker/configs/cron/laravel-scheduler /etc/supercronic/conf.d/laravel-scheduler
COPY --chown=www-data:www-data docker/configs/supervisor/ /etc/supervisor/conf.d/
COPY --chown=www-data:www-data --chmod=755 docker/configs/start-container /usr/local/bin/start-container


# Copy the application code and dependencies from the build stage
COPY --from=builder --chown=www-data:www-data /var/www /var/www

# Set working directory
WORKDIR /var/www

# Ensure correct permissions
RUN chown www-data:www-data /var/www && chown -R www-data:www-data /var/www/storage /var/www/bootstrap/cache /var/www/public

# Switch to the non-privileged user to run the application
USER www-data

#### run artisan command for setup ####


# publish package required asset(like telescope) or add it in composer:post-autoload-dump
RUN php artisan vendor:publish --tag=laravel-assets --no-ansi --force
RUN mkdir /var/www/public-link
# Default command: Provide a bash shell to allow running any command
ENTRYPOINT [ "start-container" ]

CMD ["serve"]
