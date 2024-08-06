# arches-via-docker
Deployment of Arches (archesproject.org) via Docker. We initially developed this repo to simplify and streamline deployment of Arches for use in archaeology and related instruction.



# Public Web Server and Localhost Deployments

This main goal of this repo is to offer a simple, turnkey approach to deploying HTTPS secured Arches on the Web. However, this branch provides a simple approach to deploying the dev 7.6.x version of Arches for use on a `localhost` without starting Docker related to Web hosting (Nginx, SSL, etc.). Be sure to leave Arches with the Django `DEBUG` setting as `True`. See below for instructions on creating and editing an `.env` file.


# The directories and files
The following lists some information about the contents of this repo and how they fit together:

* `docker-compose.yml`
* `.env` - specifies `COMPOSE_PROJECT_NAME` to make container names independent from the base directory name. specifies project configuration, e.g. domain names, emails, database connection details, etc. This file contains sensitive information.
* `arches/`
    * `Dockerfile`
    * `arches_data` - A directory on your host machine that gets attached to the Arches container. This makes it convenient to pass data (like packages or exports) in and out of your Arches container.
    * `conf.d/` - A directory of Supervisord configurations for the celery worker and celery beat processes. This gets copied into the Arches container.
    * `celery.py` - Editable file if you want to modify your Arches project use of celery
    * `arches_proj-supervisor.conf` - Supervisord configurations for the celery worker and celery beat processes
    * `entrypoint.sh` - entrypoint script. This has some handy utility functions for some routine administration of the Arches container.
    * `settings_local.py` - Editable python file to define project specific settings for your Arches instance. Many of the environment variables that you assign in your `.env` file
    * `settings_local.py` - Editable python file configuring URLs in your Arches instance
* `webpack/`
    * `Dockerfile`
    * `webpack_entrypoint.sh` - The `webpack` container is a minimalist container that invokes a docker command on the `arches` container. This command prepares static assets for the Arches frontend by running webpack and collectstatic.


## Prerequisites

1. [Docker](https://docs.docker.com/engine/install/) and [Docker Compose](https://docs.docker.com/compose/install/) are installed.
2. You have cloned this repository, and if deployting to a localhost only you use the `local` branch:
   ```bash
   git clone https://github.com/opencontext/arches-via-docker.git
   git checkout origin/local
   ```

### Note:
This approach will setup the most current stable version of Arches (now v7.4.2) suitable for running on a localhost for testing purposes. If you want to deploy Arches version 6 (specifically stable version 6.2.4), please switch to the `v6` branch of this repo, with:
   ```bash
   git checkout origin/v6
   ```

If you want to deploy the latest stable version of Arches to a public (or organizational) Web server, use the `main` branch:
   ```bash
   git checkout origin/main
   ```


## Step 1 - edit the configuration

Specify you domain names and contact emails for these domains in the `edit_dot_env` file and then save this file as `.env`:

First make an `.env` file
```bash
cp edit_dot_env .env
```

Now edit `.env` file to change your settings.
```bash
nano .env
```


Below are properties to edit to change how Arches deploy. If you want to deploy this on your own machine (localhost), setting `DJANGO_DEBUG=True` is useful to see and diagnose useful error messages in the Arches Django application. Be sure to set `DJANGO_DEBUG=False` for deployments on the public Web. *NOTE* if you run this on your localhost, this Docker build will currently make your Arches application available to your browser via [http://127.0.0.1:8004/](http://127.0.0.1:8004/) *on port 8004*, not the usual 8000. This nonstandard port was chosen in case your local host has other applications already running on port 8000.

If you set `BUILD_PRODUCTION=True`, be sure you have well over 8GB of system RAM. `BUILD_PRODUCTION=True` will invoke the Arches `manage.py build_production` command, and this command is *very* resource intensive and time consuming. You will likely get errors that will cause your build to fail if you do a production build on a server with only 8GB of RAM.

```properties
DJANGO_MODE=DEV
DJANGO_DEBUG=True
...
BUILD_PRODUCTION=False
```


## Step 2 - Build images and start containers

```bash
docker compose up --build
```

## Config Changes? - Replace volumes etc to implement changes

Stop the containers:

```bash
docker compose down
```


## How to Make Arches (administrative) Management Commands
Currently this will setup an "empty" Arches instance. You'll need to load it with your own data by loading a package or some other approach. Once you deploy Arches, you can use normal Arches management commands as so:

```bash
docker exec -it arches python3 manage.py [Arches management commands and arguments here]
```



## NOTE
You may run into weirdness permissions issues restarting the docker container. I solved it with:
```
sudo chmod 666 /var/run/docker.sock

```


# BACKGROUND AND CREDIT
This repo will hopefully streamline deployment of Arches for use on the Web. Eventually, we hope to use this as the basis for deploying instances of Arches for use in archaeological teaching and learning applications.

None of this code is very original. This repo started by forking:
https://github.com/evgeniy-khist/letsencrypt-docker-compose

Some elements of this repo are also derived from:
https://github.com/opencontext/oc-docker

and

https://github.com/archesproject/arches-for-science-prj

and

https://github.com/archesproject/arches-dependency-containers

and finally

https://github.com/archesproject/arches-her
