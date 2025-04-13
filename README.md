# laravel + react + docker

this repo is forked from [react-starter-kit](https://github.com/laravel/react-starter-kit) for sample Dockerized Laravel project.

In this project, I tried to implement two different Laravel runtime modes in the best possible way: the first one using [Octane](https://laravel.com/docs/master/octane), and the second one with PHP-FPM + Nginx with same dockerfile for build.
In this Dockerfile, I’ve tried to follow best practices for layout and structure, but there’s always room for improvement. If you have any suggestions, I’d be happy to collaborate and hear your ideas.



Each mode has its own Docker Compose file, but overall they’re quite similar. The main difference lies in the Nginx container, which is not required when using Octane. In the PHP-FPM setup, Nginx is responsible for forwarding requests to PHP-FPM [see nginx config file](docker/compose-configs/nginx/default.conf).

One of the main challenges with the PHP-FPM approach is handling the [public](public/) directory, which needs to be shared between the Nginx and Laravel containers.(This does not apply to octane because itself serves static files) The issue arises when a volume is already created for the public folder—on container startup, this volume overrides the public directory inside the Laravel container. As a result, updates to the image never reflect in this folder unless the volume is manually removed each time.

Currently, the only solution that seems to work (although it's not ideal) is to copy the public folder into a separate-diffrent directory called [public-link](Dockerfile#139) during container startup, and then share that directory with the Nginx container [see it](docker-compose-fpm.yml#10-13).

Here’s how it works:

1. The API container starts and forcefully copies the data from the existing public_vol volume into /var/www/public-link.

2. Then, using the container’s entrypoint script, the public directory is again force-copied into public-link [see it](docker/configs/start-container#6).

This way, the contents of the public folder are always kept up-to-date, even if the base image changes.


For handling the queue and scheduler, I used separate containers for more scalibillity, its managed by [supervisord](supervisord.org) for queue, [supercronic](https://github.com/aptible/supercronic) for scheduler. That said, it's also possible to run them without supervisord by simply changing the container's CMD like:
```
...
CMD: ["php", "/var/www/artisan", "horizon"]
....
```

### customization dockerfile

1. if you want to use custom php.ini config [change this line](Dockerfile#104-105).
2. if you want to install custom package/extension in build stage [edit here](Dockerfile#37) and in runtime [edit here](Dockerfile#96).



