# arches-via-docker
Deployment of Arches (archesproject.org) via Docker. We initially developed this repo to simplify and streamline deployment of Arches for use in archaeology and related instruction.




# Public Web Server and Localhost Deployments

This main goal of this repo is to offer a simple, turnkey approach to deploying HTTPS secured Arches on the Web. You can also use this to deploy Arches for use on a `localhost` by leaving Arches with the Django `DEBUG` setting as `True`. See below for instructions on creating and editing an `.env` file.


# Nginx and Let’s Encrypt with Docker Compose in less than 3 minutes

This example automatically obtains and renews [Let's Encrypt](https://letsencrypt.org/) TLS certificates and set up HTTPS in Nginx for multiple domain names using Docker Compose.

You can set up HTTPS in Nginx with Let's Encrypt TLS certificates for your domain names and get A+ rating at [SSL Labs SSL Server Test](https://www.ssllabs.com/ssltest/) by changing a few configuration parameters of this example.

Let's Encrypt is a certificate authority that provides free X.509 certificates for TLS encryption. The certificates are valid for 90 days and can be renewed. Both initial creation and renewal can be automated using [Certbot](https://certbot.eff.org/).

When using Kubernetes Let's Encrypt TLS certificates can be easily obtained and installed using [Cert Manager](https://cert-manager.io/). For simple web sites and applications Kubernetes is too much overhead and Docker Compose is more suitable.
But for Docker Compose there is no such popular and robust tool for TLS certificate management.

The example supports separate TLS certificates for multiple domain names, e.g. example.com, anotherdomain.net etc.
For simplicity this example deals with the following domain names:

* teach-with-arches.org

The idea is simple. There are 3 containers:

* Nginx
* Certbot - for obtaining and renewing certificates
* Cron - for triggering certificates renewal once a day

The sequence of actions:

* Nginx generates self-signed "dummy" certificates to pass ACME challenge for obtaining Let's Encrypt certificates
* Certbot waits for Nginx to become ready and obtains certificates
* Cron triggers Certbot to try to renew certificates and Nginx to reload configuration on a daily basis
* The Nginx container uses updates symbolic links that point to either "dummy" certificates or Let's Encrypt certificates.

# The directories and files:

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
* `certbot/`
    * `Dockerfile`
    * `certbot.sh` - entrypoint script
* `cron/`
    * `Dockerfile`
    * `renew_certs.sh` - script executed on a daily basis to try to renew certificates
* `html/` - directory mounted as `root` for Nginx
    * `index.html`
* `nginx/`
    * `Dockerfile`
    * `nginx.sh` - entrypoint script. This script will update where symbolic links will resolve (either to the dummy self-assigned certificates or to the Let's Encrypt obtained certificates)
    * `hsts.conf` - HTTP Strict Transport Security (HSTS) policy
    * `options-ssl-nginx.conf` - SSL related configurations
    * `default.conf` - Nginx configuration for your domain. Contains a configuration to get A+ rating at [SSL Server Test](https://www.ssllabs.com/ssltest/). This configuration also asks Nginx to gzip compress certain text-based static files (especially CSS and Javascript) which should help with performance. This config uses symbolic links to specify the path to SSL certificates.
    * `default.conf` - Nginx server configuration. It loads the Perl language module to simplify passing environment variables to your Nginx domain configuration.
* `webpack/`
    * `Dockerfile`
    * `webpack_entrypoint.sh` - The `webpack` container is a minimalist container that invokes a docker command on the `arches` container. This command prepares static assets for the Arches frontend by running webpack and collectstatic.

To adapt the example to your domain names you need to change only `.env`:

```properties
DOMAINS=teach-with-arches.org
CERTBOT_EMAILS=info@teach-with-arches.org info@teach2.with.arches.org
CERTBOT_TEST_CERT=0
CERTBOT_RSA_KEY_SIZE=4096
```

Configuration parameters:

* `DOMAINS` - a space separated list of domains to manage certificates for
* `CERTBOT_EMAILS` - a space separated list of email for corresponding domains. If not specified, certificates will be obtained with `--register-unsafely-without-email`
* `CERTBOT_TEST_CERT` - use Let's Encrypt staging server (`--test-cert`)

Let's Encrypt has rate limits. So, while testing it's better to use staging server by setting `CERTBOT_TEST_CERT=1` (default value).
When you are ready to use production Let's Encrypt server, set `CERTBOT_TEST_CERT=0`.

## Prerequisites

1. [Docker](https://docs.docker.com/engine/install/) and [Docker Compose](https://docs.docker.com/compose/install/) are installed.
2. You have a domain name
3. You have a server with a publicly routable IP address
4. You have cloned this repository
   ```bash
   git clone https://github.com/opencontext/arches-via-docker.git
   ```

## Step 0 - Point your domain to server with DNS A records

For all domain names configure DNS A records to point to a server where Docker containers will be running.

## Step 1 - Edit domain names, emails and other variables in the configuration

Specify you domain names and contact emails for these domains in the `edit_dot_env` file and then save this file as `.env`:

First make an `.env` file
```bash
cp edit_dot_env .env
```

Now edit `.env` file to change your settings.
```bash
nano .env
```

Here are properties to change based on your specific Web domain. Please note, for now this only supports one domain specified by the `DOMAINS` variable (the plural is asperational..).

```properties
DOMAINS=teach-with-arches.org
CERTBOT_EMAILS=info@teach-with-arches.org
```

Below are properties to edit to change how Arches deploy. If you want to deploy this on your own machine (localhost), setting `DJANGO_DEBUG=True` is useful to see and diagnose useful error messages in the Arches Django application, but be sure to set `DJANGO_DEBUG=False` for deployments on the public Web. *NOTE* if you run this on your localhost, this Docker build will currently make your Arches application available to your browser via [http://127.0.0.1:8004/](http://127.0.0.1:8004/) *on port 8004*, not the usual 8000. This nonstandard port was chosen in case your local host has other applications already running on port 8000.

If you set `BUILD_PRODUCTION=True`, be sure you have well over 8GB of system RAM. `BUILD_PRODUCTION=True` will invoke the Arches `manage.py build_production` command, and this command is *very* resource intensive and time consuming. You will likely get errors that will cause your build to fail if you do a production build on a server with only 8GB of RAM.

```properties
DJANGO_MODE=DEV
DJANGO_DEBUG=False
...
BUILD_PRODUCTION=False
```



## Step 2 - Create named Docker volumes for dummy and Let's Encrypt TLS certificates

```bash
docker volume create --name=logs_nginx
docker volume create --name=nginx_ssl
docker volume create --name=certbot_certs
docker volume create --name=arches_certbot
```

## Step 3 - Use Valid Let's Encrypt Certificates
Configure to use production Let's Encrypt server in `.env`:

```properties
CERTBOT_TEST_CERT=0
```

## Step 4 - Build images and start containers

```bash
docker compose up --build
```

## Config Changes? - Replace volumes etc to implement changes

Stop the containers:

```bash
docker compose down
```

Re-create the volume for Let's Encrypt certificates:

```bash
docker volume rm certbot_certs
docker volume rm arches_certbot
docker volume create --name=certbot_certs
docker volume create --name=arches_certbot
```

Start the containers:

```bash
docker compose up
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
