FROM ubuntu:22.04
# Start with Ubuntu 22

USER root

# Do the apt installation also install git
RUN apt-get update && && apt-get install -y --no-install-recommends \
    python3.12 \
    python3.12-dev \
    python3.12-venv \
    python3-pip \
    make software-properties-common \
    curl \
    gcc \
    build-essential \
    mime-support \
    libgdal-dev \
    dos2unix \
    nano
RUN apt-get update --fix-missing && apt-get install -y git


# Install the postgres client
RUN apt-get update
RUN apt-get install -y postgresql-client-14


FROM python:3.12
# set environment variables
ENV PYTHONDONTWRITEBYTECODE 1
ENV PYTHONUNBUFFERED 1

RUN python -m venv venv \
    && . venv/bin/activate \
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
# for the Arches HER repo
ENV HER_REPO_PATH=${ARCHES_ROOT}/arches_her
# settings_local.py provides the DB credentials, etc. to the Arches project.
ENV SETTINGS_PATH=${APP_COMP_FOLDER}/settings.py
ENV SETTINGS_LOCAL_PATH=${APP_COMP_FOLDER}/settings_local.py
ENV CELERY_PATH=${APP_COMP_FOLDER}/celery.py
ENV URLS_PATH=${APP_COMP_FOLDER}/urls.py
ENV ARCHES_DATA=${ARCHES_ROOT}/arches_data
ENV PACKAGE_PATH=${APP_COMP_FOLDER}/package.json
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
    " \
    && apt-get install -y --no-install-recommends curl \
    && curl -sL https://deb.nodesource.com/setup_16.x | bash - \
    && curl -sL https://www.postgresql.org/media/keys/ACCC4CF8.asc | apt-key add - \
    && add-apt-repository "deb http://apt.postgresql.org/pub/repos/apt/ $(lsb_release -sc)-pgdg main" \
    && apt-get update -y \
    && apt-get install -y "wait-for-it" \
    && apt-get install -y nano \
    && apt-get install -y --no-install-recommends $RUN_DEPS



# ----------------------------------------------
# Do installs relating to yarn
# ----------------------------------------------


# Install yarn
# Install Node.js
# RUN apt-get install -y nodejs \
#     && npm install -g yarn

# Clean up
RUN apt-get clean \
    && rm -rf /var/lib/apt/lists/* /tmp/* /var/tmp/*




WORKDIR ${ARCHES_ROOT}

RUN rm -rf /root/.cache/pip/*

RUN pip install --upgrade pip
# Install the Arches application and make an Arches project.
RUN pip install supervisor==4.2.1 \ 
    && pip install django-pgtrigger==4.9.0 \
    && pip install django-storages==1.13.2 \
    && pip install arches-templating>=0.1.2 \
    && pip install pytz --upgrade \
    && pip install tzdata --upgrade \
    && pip install Redis \
    && pip install gunicorn \
    && pip install pyasynchat \
    && pip install pyasyncore \
    && pip install arches==7.5.5 \
    && pip install python-docx==1.1.0

# Install the HER software and the working v7 branch
RUN mkdir -p ${HER_REPO_PATH}

WORKDIR ${ARCHES_ROOT}
RUN git clone https://github.com/archesproject/arches-her.git ${HER_REPO_PATH}
WORKDIR ${HER_REPO_PATH}
RUN echo "Use the arches-her dev/1.1.x";
RUN echo "git checkout dev/1.1.x";
RUN git checkout dev/1.1.x;
RUN pip install -e '.[dev]'



# copy in local settings to our newly created Arches project.
WORKDIR ${ARCHES_ROOT}

# create a new Arches project
RUN mkdir -p /new_arches_proj
RUN arches-admin startproject ${ARCHES_PROJECT} --directory /new_arches_proj
RUN mv /new_arches_proj ${APP_ROOT}

WORKDIR ${APP_ROOT}
COPY ./arches/settings.py ${SETTINGS_PATH}
RUN sed -i 's/\r$//g' ${SETTINGS_PATH}
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

# Copy customized package until the issue with datatables.net is resolved.
COPY ./arches/package.json ${PACKAGE_PATH}

# copy the celery supervisor
COPY /arches/conf.d/ ${APP_ROOT}/conf.d/
RUN chmod -R 700 ${APP_ROOT}/conf.d/
COPY /arches/arches_her_local-supervisor.conf ${APP_ROOT}/arches_her_local-supervisor.conf
RUN chmod -R 700 ${APP_ROOT}/arches_her_local-supervisor.conf
RUN mkdir -p /var/log/supervisor
RUN mkdir -p /var/log/celery


# Set some settings to make NPM less fussy
# RUN npm config set cafile null
# RUN npm config set strict-ssl false

# remove any node_modules that might have been installed by the arches install
# RUN rm -rf ${APP_ROOT}/node_modules
# RUN rm -f ${APP_ROOT}/package-lock.json
# Now do the NPM install
# RUN npm install






# Make sure the entry point is available and lacks weird characters
# that don't work in a Linux OS
COPY /arches/entrypoint.sh ${APP_ROOT}/entrypoint.sh
RUN chmod -R 700 ${APP_ROOT}/entrypoint.sh &&\
  dos2unix ${APP_ROOT}/entrypoint.sh

WORKDIR ${APP_ROOT}
RUN mkdir -p ${APP_COMP_FOLDER}/media
RUN chmod -R 744 ${APP_COMP_FOLDER}/media

# install nvm
ENV NODE_VERSION 16.20.1
ENV NVM_DIR /usr/local/nvm
RUN mkdir $NVM_DIR
# https://github.com/nvm-sh/nvm#install-script
RUN curl --silent -o- https://raw.githubusercontent.com/nvm-sh/nvm/v0.39.4/install.sh | bash -
# install node and npm
WORKDIR ${APP_COMP_FOLDER}
RUN echo "source $NVM_DIR/nvm.sh \
  && nvm install $NODE_VERSION \
  && nvm alias default $NODE_VERSION \
  && nvm use default" | bash -

# add node and npm to path so the commands are available
ENV NODE_PATH $NVM_DIR/v$NODE_VERSION/lib/node_modules
ENV PATH $NVM_DIR/versions/node/v$NODE_VERSION/bin:$PATH

RUN npm install -g yarn && apt install wait-for-it

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
