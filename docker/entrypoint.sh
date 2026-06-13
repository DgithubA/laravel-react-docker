#!/bin/sh
set -e

container_startup() {
    if [ -f /usr/local/bin/startup.sh ]; then
        echo "execute startup.sh...."
        /usr/local/bin/startup.sh
    fi
}

make_enable() {
    src="/etc/supervisor.d/conf.available/$1.ini"
    dst="/etc/supervisor.d/conf.enabled/$1.ini"

    if [ -f "$src" ]; then
        ln -sf "$src" "$dst"
    fi
}

container_startup

mkdir -p /etc/supervisor.d/conf.enabled
rm -f /etc/supervisor.d/conf.enabled/*.ini || true

if [ "$1" = "run" ]; then
    shift

    if [ $# -eq 0 ]; then
        set -- laravel-web laravel-worker laravel-schedule
    fi

    for service in "$@"; do
        echo "enable $service..."
        make_enable "$service"
    done
    exec supervisord -c /etc/supervisor.d/supervisord.ini
fi

exec "$@"
