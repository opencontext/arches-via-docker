FROM ubuntu:22.04
# Start with Ubuntu 22

USER root

# Set environment variables to make installations non-interactive
ENV DEBIAN_FRONTEND=noninteractive
ENV TZ=UTC

# Update package lists and install basic packages first
RUN apt-get update && apt-get install -y --no-install-recommends \
    curl \
    wget \
    gnupg \
    lsb-release \
    software-properties-common \
    && apt-get clean \
    && rm -rf /var/lib/apt/lists/*

# Add Python 3.13 repository and install Python packages
RUN add-apt-repository ppa:deadsnakes/ppa \
    && apt-get update \
    && apt-get install -y --no-install-recommends \
    python3.13 \
    python3.13-dev \
    python3.13-venv \
    python3-pip \
    && apt-get clean \
    && rm -rf /var/lib/apt/lists/*

# Install system dependencies
RUN apt-get update \
    && apt-get install -y --no-install-recommends \
    make \
    gcc \
    build-essential \
    mime-support \
    libgdal-dev \
    dos2unix \
    nano \
    git \
    postgresql-client-14 \
    && apt-get clean \
    && rm -rf /var/lib/apt/lists/*

# set environment variables
ENV PYTHONDONTWRITEBYTECODE 1
ENV PYTHONUNBUFFERED 1

# Set up a virtual environment to use for all later commands.
RUN python3.13 -m venv /opt/venv \
    && . /opt/venv/bin/activate \
    && pip install --upgrade pip
# Make sure we use the virtualenv:
ENV PATH="/opt/venv/bin:$PATH"

## Setting default environment variables
ARG ARCHES_ROOT
# The name of the arches project
ARG ARCHES_PROJECT
# Project specific paths
ARG APP_ROOT
ARG APP_COMP_FOLDER
ARG UPLOADED_FILES_FOLDER

# settings_local.py provides the DB credentials, etc. to the Arches project.
ENV SETTINGS_PATH=${APP_COMP_FOLDER}/settings.py
ENV SETTINGS_LOCAL_PATH=${APP_COMP_FOLDER}/settings_local.py
ENV CELERY_PATH=${APP_COMP_FOLDER}/celery.py
ENV URLS_PATH=${APP_COMP_FOLDER}/urls.py
ENV GUNICORN_CONFIG_PATH=${APP_COMP_FOLDER}/gunicorn_config.py
ENV ARCHES_DATA=${ARCHES_ROOT}/arches_data
ENV PACKAGE_PATH_USE=${APP_ROOT}/package.json
ENV ESLINT_CONFIG_MJS_PATH_USE=${APP_ROOT}/eslint.config.mjs
ENV UPLOADED_FILES_FOLDER=${UPLOADED_FILES_FOLDER}
ENV WHEELS=/wheels
ENV PYTHONUNBUFFERED=1
ENV PYTHONDONTWRITEBYTECODE 1

# Setup needed directories
RUN mkdir ${ARCHES_ROOT} && mkdir /var/log/supervisor && mkdir /var/log/celery

# Get ready to do some code installation
RUN apt-get update && apt-get install -y make software-properties-common

# Install packages required to run Arches
# Note that the ubuntu/debian package for libgdal1-dev pulls in libgdal1i, which is built
# with everything enabled, and so, it has a huge amount of dependancies (everything that GDAL
# support, directly and indirectly pulling in mysql-common, odbc, jp2, perl! ... )
# a minimised build of GDAL could remove several hundred MB from the container layer.
RUN set -ex \
    && RUN_DEPS=" \
        build-essential \
        libxml2-dev \
        libproj-dev \
        libjson-c-dev \
        xsltproc \
        docbook-xsl \
        docbook-mathml \
        libgdal-dev \
        libpq-dev \
        mime-support \
        python3-dev \
        postgresql-client-14 \
        dos2unix \
        wait-for-it \
        nano \
    " \
    && curl -sL https://deb.nodesource.com/setup_16.x | bash - \
    && curl -sL https://www.postgresql.org/media/keys/ACCC4CF8.asc | gpg --dearmor -o /usr/share/keyrings/postgresql-keyring.gpg \
    && echo "deb [signed-by=/usr/share/keyrings/postgresql-keyring.gpg] http://apt.postgresql.org/pub/repos/apt/ $(lsb_release -cs)-pgdg main" | tee /etc/apt/sources.list.d/postgresql.list \
    && apt-get update -y \
    && apt-get install -y --no-install-recommends $RUN_DEPS \
    && apt-get clean \
    && rm -rf /var/lib/apt/lists/* /tmp/* /var/tmp/*




# ----------------------------------------------
# Do installs relating to Node
# ----------------------------------------------

# Set environment variables
ENV NODE_MAJOR=18

# Update package lists and install necessary packages
RUN apt-get update \
    && apt-get install -y \
        ca-certificates \
        curl \
        gnupg \
    && mkdir -p /etc/apt/keyrings

# Add nodesource GPG key
RUN curl -fsSL https://deb.nodesource.com/gpgkey/nodesource-repo.gpg.key | gpg --dearmor -o /etc/apt/keyrings/nodesource.gpg

# Add nodesource repository
RUN echo "deb [signed-by=/etc/apt/keyrings/nodesource.gpg] https://deb.nodesource.com/node_$NODE_MAJOR.x nodistro main" | tee /etc/apt/sources.list.d/nodesource.list \
    && apt-get update

# Install Node.js
RUN apt-get install -y nodejs

# Clean up
RUN apt-get clean \
    && rm -rf /var/lib/apt/lists/* /tmp/* /var/tmp/*




WORKDIR ${ARCHES_ROOT}

RUN rm -rf /root/.cache/pip/*

RUN pip install --upgrade pip
RUN pip install --force-reinstall -U setuptools

# Install the current stable release of the Arches application and make an Arches project.
RUN pip install supervisor \
    && pip install pytz --upgrade \
    && pip install tzdata --upgrade \
    && pip install Redis \
    && pip install gunicorn \
    && pip install arches

# create a new Arches project
RUN mkdir -p /new_arches_proj
RUN arches-admin startproject ${ARCHES_PROJECT} --directory /new_arches_proj
RUN mv /new_arches_proj ${APP_ROOT}

# create the uploaded files folder
RUN mkdir -p ${UPLOADED_FILES_FOLDER}

# copy in local settings to our newly created Arches project.
WORKDIR ${APP_ROOT}
COPY ./arches/settings_local.py ${SETTINGS_LOCAL_PATH}
RUN sed -i 's/\r$//g' ${SETTINGS_LOCAL_PATH}
# copy the celery.py file into out archaes project. This hopefully makes the workers and beat work:
COPY ./arches/celery.py ${CELERY_PATH}
RUN sed -i 's/\r$//g' ${CELERY_PATH}
# copy the urls.py into our new Arches project. This is part of
# customization for internationalization
RUN echo "copied urls to ${URLS_PATH}";
COPY ./arches/urls.py ${URLS_PATH}
RUN sed -i 's/\r$//g' ${URLS_PATH}

# Copy the gunicorn_config.py file into our new Arches project. This is used
# for running Arches in production (not DEBUG mode)
# NOTE: We're NOT actually using this, because it will throw an error with urls.py 
# So this is here for reference only in case someone wants to edit gunicorn_config.py
# and figure out how to make it work.
RUN echo "copy gunicorn_config.py to ${GUNICORN_CONFIG_PATH}";
COPY ./arches/gunicorn_config.py ${GUNICORN_CONFIG_PATH}
RUN sed -i 's/\r$//g' ${GUNICORN_CONFIG_PATH}

# Copy customized package until the issue with datatables.net is resolved.
# COPY ./arches/package.json ${PACKAGE_PATH}

# copy the celery supervisor
COPY /arches/conf.d/ ${APP_ROOT}/conf.d/
RUN chmod -R 700 ${APP_ROOT}/conf.d/
COPY /arches/arches_slocal-supervisor.conf ${APP_ROOT}/arches_slocal-supervisor.conf
RUN chmod -R 700 ${APP_ROOT}/arches_slocal-supervisor.conf
RUN mkdir -p /var/log/supervisor
RUN mkdir -p /var/log/celery

# Now install NPM
WORKDIR ${APP_ROOT}
# RUN echo "NPM install....";
# RUN npm install

# Set some settings to make NPM less fussy
RUN npm config set cafile null
RUN npm config set strict-ssl false

# remove any node_modules that might have been installed by the arches install
RUN rm -rf ${APP_ROOT}/node_modules
RUN rm -f ${APP_ROOT}/package-lock.json
# Now do the NPM install
RUN npm install

# Make sure the entry point is available and lacks weird characters
# that don't work in a Linux OS
COPY /arches/entrypoint.sh ${APP_ROOT}/entrypoint.sh
RUN chmod -R 700 ${APP_ROOT}/entrypoint.sh &&\
  dos2unix ${APP_ROOT}/entrypoint.sh


# Set default workdir
WORKDIR ${APP_ROOT}
ENTRYPOINT ["./entrypoint.sh"]
CMD ["run_arches"]


# Set default workdir
WORKDIR ${APP_ROOT}
# Expose port 8000 (Django server)
EXPOSE 8000
# Expose Webpack port
EXPOSE 8021
# Expose CouchDB port
EXPOSE 5984
