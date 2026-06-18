# syntax=docker/dockerfile:latest
ARG NODE_VERSION=22
ARG PHP_VERSION=8.3-fpm
FROM node:${NODE_VERSION}-alpine AS nodeimage
FROM php:${PHP_VERSION}-alpine AS base

# Install system dependencies
RUN apk update && apk add --no-cache \
    bash curl ca-certificates git unzip  \
    supervisor dcron zip tzdata nginx sqlite \
    && rm -rf /var/cache/apk/*

# https://github.com/mlocati/docker-php-extension-installer
ADD --chmod=0755 https://github.com/mlocati/docker-php-extension-installer/releases/latest/download/install-php-extensions /usr/local/bin/

# core extentions:
# ctype curl date dom fileinfo filter hash iconv json libxml
# mbstring mysqlnd openssl pcre PDO pdo_sqlite Phar posix random
# readline Reflection session SimpleXML sodium SPL sqlite3 standard
# tokenizer xml xmlreader xmlwriter Zend OPcache zlib  Zend OPcache

#install required extention
RUN install-php-extensions gd mongodb redis \
    pdo_mysql pdo_pgsql bcmath exif gettext zip intl


ARG WORKDIR=/var/www/html
WORKDIR $WORKDIR
ARG USER_NAME=www-data
ENV USER_NAME=${USER_NAME}
ARG GROUP_NAME=www-data
ENV GROUP_NAME=${GROUP_NAME}

RUN mkdir -p /var/log/supervisor /var/log/nginx /var/cache/nginx /etc/nginx/conf.d &&  \
    touch /var/run/nginx.pid && \
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

FROM base AS make

# Install Composer
COPY --from=composer:latest /usr/bin/composer /usr/bin/composer

#Install node
COPY --from=nodeImage /usr/local/bin /usr/local/bin
COPY --from=nodeImage /usr/local/lib /usr/local/lib

COPY composer.* .
# Install dependencies
RUN composer install --no-dev --no-autoloader --no-interaction --no-progress --prefer-dist --no-scripts --no-ansi

# Copy built assets
COPY package*.json .

RUN npm ci || npm i

# Copy the entire Laravel application code into the container
COPY --exclude=docker . .

# dump autoload after install dependencies
RUN composer dump-autoload --optimize --no-interaction --no-ansi

# build npm
RUN npm run build

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

RUN chmod +x /usr/local/bin/entrypoint.sh /usr/local/bin/startup.sh /usr/sbin/crond

COPY --from=make --chown=${USER_NAME}:${GROUP_NAME} --exclude=node_modules $WORKDIR .

USER ${USER_NAME}
EXPOSE 80
ENTRYPOINT ["entrypoint.sh"]
CMD ["run","laravel-web"]
