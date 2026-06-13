# syntax=docker/dockerfile:latest
ARG NODE_VERSION=22
ARG PHP_VERSION=8.3-fpm
FROM node:${NODE_VERSION}-alpine AS nodeimage
FROM php:${PHP_VERSION}-alpine AS base
# Install system dependencies and PHP extensions
RUN apk update && apk add --no-cache \
    mariadb-client \
    mongodb-tools \
    bash \
    supervisor \
    dcron \
    zip \
    libzip-dev \
    freetype-dev \
    libjpeg-turbo-dev \
    libpng-dev \
    oniguruma-dev \
    gettext-dev \
    curl-dev \
    autoconf \
    gcc \
    make \
    musl-dev \
    nodejs-current  \
    npm  \
    sqlite \
    tzdata \
    nginx curl ca-certificates \
    && rm -rf /var/cache/apk/*

# Install required extension
RUN docker-php-ext-install pcntl && pecl install redis && docker-php-ext-enable redis \
    && pecl install mongodb && docker-php-ext-enable mongodb \
    && docker-php-ext-configure gd --with-freetype --with-jpeg \
    && docker-php-ext-install pdo pdo_mysql gd bcmath exif gettext opcache

# Install Composer
COPY --from=composer:latest /usr/bin/composer /usr/bin/composer

#Install node
COPY --from=nodeImage /usr/local /usr/local

ARG WORKDIR=/var/www/html
WORKDIR $WORKDIR
ARG USER_NAME=www-data
ENV USER_NAME=${USER_NAME}
ARG GROUP_NAME=www-data
ENV GROUP_NAME=${GROUP_NAME}


RUN mkdir -p /var/log/supervisor /var/log/nginx /var/cache/nginx /etc/nginx/conf.d

RUN touch /var/run/nginx.pid && \
    chown -R $USER_NAME:$USER_NAME \
    $PHP_INI_DIR/conf.d/ \
    /var/cache \
    /etc/nginx/ \
    /var/lib/nginx \
    /var/log \
    /etc/nginx \
    /tmp \
    /run \
    /etc/supervisord.conf \
    /var/run/nginx.pid

FROM base AS composer

# Copy composer required file for install dependencies
COPY --chown=${USER_NAME}:${GROUP_NAME} composer.* .

USER ${USER_NAME}

# Install dependencies
RUN composer install --no-dev --no-autoloader --no-interaction --no-progress --prefer-dist --no-scripts --no-ansi

FROM base AS npm-install

# Copy built assets
COPY --chown=${USER_NAME}:${GROUP_NAME} package*.json .

USER ${USER_NAME}

RUN npm ci || npm i

FROM base AS main

# Copy Supervisor Config file
COPY --chown=${USER_NAME}:${GROUP_NAME} docker/supervisor.d /etc/supervisor.d

# Add the Laravel cron job to the container
COPY --chown=${USER_NAME}:${GROUP_NAME} docker/laravel-schedule /etc/cron.d/laravel-cron

# Copy nginx config file and edit main config
COPY --chown=${USER_NAME}:${GROUP_NAME} docker/nginx/http.d/default.conf /etc/nginx/http.d/default.conf
COPY --chown=${USER_NAME}:${GROUP_NAME} docker/nginx/conf.d/default.conf /etc/nginx/conf.d/custom.conf

# Configure PHP-FPM
COPY --chown=${USER_NAME}:${GROUP_NAME} docker/fpm-pool.conf ${PHP_INI_DIR}/../php-fpm.d/www2.conf
COPY --chown=${USER_NAME}:${GROUP_NAME} docker/php.ini ${PHP_INI_DIR}/conf.d/custom.ini

# Copy entrypoint script
COPY --chown=${USER_NAME}:${GROUP_NAME} docker/entrypoint.sh docker/startup.sh /usr/local/bin/

RUN chmod +x /usr/local/bin/entrypoint.sh /usr/local/bin/startup.sh

RUN chmod +x /usr/sbin/crond


COPY --from=composer $WORKDIR .
COPY --from=npm-install $WORKDIR .

# Copy the entire Laravel application code into the container
COPY --chown=${USER_NAME}:${GROUP_NAME} --exclude=docker . .

USER ${USER_NAME}

# dump autoload after install dependencies
RUN composer dump-autoload --optimize --no-interaction --no-ansi

# build npm
RUN npm run build


EXPOSE 80
ENTRYPOINT ["entrypoint.sh"]
CMD ["run","laravel-web"]
