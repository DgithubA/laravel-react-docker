#!/bin/sh

php artisan optimize:clear
php artisan migrate --force
php artisan storage:link || true
