# arches-via-docker
Deployment of [Arches for Science](https://www.archesproject.org/arches-for-science/) via Docker. We initially developed this repo to simplify and streamline deployment of Arches for Science (AfS) to make testing of development branches easier. This deployment attempts to implement, using Docker, instructions for deploying AfS version dev/2.0.x as documented here: [https://github.com/archesproject/arches-for-science/tree/dev/2.0.x#readme](https://github.com/archesproject/arches-for-science/tree/dev/2.0.x#readme)



# Public Web Server and Localhost Deployments

This branch provides a simple approach to deploying AfS for use on a `localhost`. It does not start other Docker containers related to Web hosting (Nginx, SSL, etc.). Be sure to leave Arches with the Django `DEBUG` setting as `True`. See below for instructions on creating and editing an `.env` file.

This branch has only partial support for installing arbitrary versions of AfS. Configure the `.env` file to name the branch you'd like to deploy as so:

   ```
   AFS_GIT_BRANCH="dev/2.0.x"
   ```

# Caveats
The Arches docker container will git-clone the Arches for Science and the Arches repositories and switch to the desired branch and then install the various Python dependencies. However, installation of other dependencies outside of Python are still "hard-coded" in the Arches Dockerfile. So you may need to manually edit that file if the version of AfS and Arches you wish to install has different non-Python dependencies.

Another caveat to note is that the name of the Arches/AfS project (`afs_plocal`) should be treated as *hardcoded*. It seems like a heavy lift to make it easy to configure the project name in Docker.


# The directories and files
The following lists some information about the contents of this repo and how they fit together:

* `docker-compose.yml`
* `.env` - specifies `COMPOSE_PROJECT_NAME` to make container names independent from the base directory name. specifies project configuration, e.g. domain names, emails, database connection details, etc. This file contains sensitive information.
* `arches/`
    * `Dockerfile`
    * `arches_data` - A directory on your host machine that gets attached to the Arches container. This makes it convenient to pass data (like packages or exports) in and out of your Arches container.
    * `conf.d/` - A directory of Supervisord configurations for the celery worker and celery beat processes. This gets copied into the Arches container.
    * `celery.py` - Editable file if you want to modify your AfS project use of celery
    * `afs_plocal-supervisor.conf` - Supervisord configurations for the celery worker and celery beat processes
    * `entrypoint.sh` - entrypoint script. This has some handy utility functions for some routine administration of the Arches container.
    * `settings.py` - Editable python file to define project specific settings for your AfS instance. Many of the environment variables that you assign in your `.env` file
    * `settings_local.py` - Another editable python file to define project specific settings for your AfS instance. Many of the environment variables that you assign in your `.env` file
    * `urls.py` - Editable python file configuring URLs in your AfS instance
* `webpack/`
    * `Dockerfile`
    * `package.json` - This specifies frontend components that get installed via `npm`.


## Prerequisites

1. [Docker](https://docs.docker.com/engine/install/) and [Docker Compose](https://docs.docker.com/compose/install/) are installed.
2. You have cloned this repository, and if deployting to a localhost only you use the `local-afs-dev-1-1-x` branch:
   ```bash
   git clone https://github.com/opencontext/arches-via-docker.git
   git checkout origin/local-afs-dev-2-x
   ```

### Note:
This branch can set up a desired version of AfS / Arches (with caveats, see above) suitable for running on a localhost for testing purposes. If you want to locally deploy the latest stable version of Arches witch to the `local` branch of this repo. If you want Arches version 6 (specifically stable version 6.2.4), please switch to the `v6` branch of this repo, with:
   ```bash
   git checkout origin/v6
   ```

If you want to deploy the latest stable version of (core) Arches to a public (or organizational) Web server, use the `main` branch:
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
docker exec -it arches python manage.py [Arches management commands and arguments here]
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
