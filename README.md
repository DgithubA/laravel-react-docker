# Laravel Multi-Service Docker Environment

this repo is forked from [react-starter-kit](https://github.com/laravel/react-starter-kit) for sample Dockerized Laravel project.


This project provides a fully dockerized Laravel environment using **Nginx, PHP-FPM, and Supervisor**, with support for multiple optional services that can be enabled dynamically at container startup.

---

# 🚀 Features

- Single Docker image for multiple runtime modes
- Dynamic service enabling via container command
- Supervisor-based process management
- Supports multiple Laravel services:
    - Web (Nginx + PHP-FPM)
    - Queue Worker
    - Scheduler
    - Reverb (WebSocket)
    - Horizon
- No need to rebuild image for different setups
- Docker-friendly logging (stdout/stderr only)

---

# Usages
 you can run container based on services you want:
```shell
docker run image run {services}
```
you also can add your own service in [conf.available](./docker/supervisor.d/conf.available) folder.

### 📦 Available Services
| Service                                                                       | Description |
|-------------------------------------------------------------------------------|-------------|
| [laravel-web](./docker/supervisor.d/conf.available/laravel-web.ini)           | Nginx + PHP-FPM (main web server) |
| [laravel-worker](./docker/supervisor.d/conf.available/laravel-worker.ini)     | Laravel queue worker |
| [laravel-schedule](./docker/supervisor.d/conf.available/laravel-schedule.ini) | Laravel scheduler (cron replacement) |
| [laravel-reverb](./docker/supervisor.d/conf.available/laravel-reverb.ini)     | Laravel Reverb WebSocket server |
| [laravel-horizon](./docker/supervisor.d/conf.available/laravel-horizon.ini)   | Laravel Horizon queue dashboard |


### 🧪 Examples

Run full stack (default):
> Default enabled services is:
> - laravel-web
> - laravel-worker
> - laravel-schedule

```shell
docker run image run
```

Run web only:
```shell
docker run image run laravel-web
```
Run WebSocket (Reverb) only:
```shell
docker run image run laravel-reverb
```
Run queue worker only:
```shell
docker run image run laravel-worker
```
Run multiple services:
```shell
docker run image run laravel-web laravel-worker laravel-reverb
```

also you can see [docker-compose.yml](./docker-compose.yml).

---

# 🧠 How It Works

At container startup:

1. Optional [startup.sh](./docker/startup.sh) is executed
2. Existing enabled supervisor configs are cleaned
3. Selected services are enabled via symlinks
4. `supervisord` is started


