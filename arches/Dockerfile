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

# Add Python 3.12 repository and install Python packages
RUN add-apt-repository ppa:deadsnakes/ppa \
    && apt-get update \
    && apt-get install -y --no-install-recommends \
    python3.12 \
    python3.12-dev \
    python3.12-venv \
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

RUN python3.12 -m venv /opt/venv \
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
# Do installs relating to yarn
# ----------------------------------------------

# Install yarn
# Install Node.js
# RUN apt-get install -y nodejs \
#     && npm install -g yarn

# Clean up
# RUN apt-get clean \
#     && rm -rf /var/lib/apt/lists/* /tmp/* /var/tmp/*




WORKDIR ${ARCHES_ROOT}

RUN rm -rf /root/.cache/pip/*

RUN pip install --upgrade pip
# Install the Arches application and make an Arches project.
RUN pip install --no-cache-dir --no-input supervisor==4.2.1 \
    && pip install --no-cache-dir --no-input django-pgtrigger==4.9.0 \
    && pip install --no-cache-dir --no-input django-storages==1.13.2 \
    && pip install --no-cache-dir --no-input arches-templating>=0.1.2 \
    && pip install --no-cache-dir --no-input pytz --upgrade \
    && pip install --no-cache-dir --no-input tzdata --upgrade \
    && pip install --no-cache-dir --no-input Redis \
    && pip install --no-cache-dir --no-input gunicorn \
    && pip install --no-cache-dir --no-input pyasynchat \
    && pip install --no-cache-dir --no-input pyasyncore \
    && pip install --no-cache-dir --no-input arches==7.5.5 \
    && pip install --no-cache-dir --no-input python-docx==1.1.0

# Install the HER software and the working v7 branch
RUN mkdir -p ${HER_REPO_PATH}

WORKDIR ${ARCHES_ROOT}
RUN git clone https://github.com/archesproject/arches-her.git ${HER_REPO_PATH}
WORKDIR ${HER_REPO_PATH}
RUN echo "Use the arches-her dev/1.1.x";
RUN echo "git checkout dev/1.1.x";
RUN git checkout dev/1.1.x;
RUN pip install --no-cache-dir --no-input -e '.[dev]'

# create a new Arches project
WORKDIR ${ARCHES_ROOT}
RUN arches-admin startproject ${ARCHES_PROJECT}

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


# Copy template files from the package
RUN echo "Copy HER templates and media to project";
RUN	cp -rn  ${HER_REPO_PATH}/arches_her/templates/* ${APP_COMP_FOLDER}/templates/
RUN	cp -rn  ${HER_REPO_PATH}/arches_her/media/* ${APP_COMP_FOLDER}/media/

# install nvm
ENV NODE_VERSION 20.19.3
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

RUN npm install -g yarn
RUN yarn install

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
