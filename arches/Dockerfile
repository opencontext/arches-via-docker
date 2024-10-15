FROM ubuntu:22.04
# Start with Ubuntu 22

USER root

# Do the apt installation also install git
RUN apt-get update && && apt-get install -y --no-install-recommends \
    python3.11 \
    python3.11-dev \
    python3.11-venv \
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

FROM python:3.11
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


# AfS Settings
ARG AFS_CLONE
ARG AFS_GIT_BRANCH
ARG AFS_REPO_DIR
ARG UPLOADED_FILES_FOLDER


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

# Install the current stable release of the Arches application and make an Arches project.
RUN pip install supervisor && pip install pytz --upgrade && pip install tzdata --upgrade && pip install Redis && pip install gunicorn && pip install arches && arches-admin startproject ${ARCHES_PROJECT}


WORKDIR ${ARCHES_ROOT}

RUN mkdir -p ${UPLOADED_FILES_FOLDER}


# This is a hack to install SSH keys inside the container. Don't use
# these for anything other than cloning public git repos, since they
# are not secure within the docker image. But we seem to need this to
# access github in the npm install process.

# We also need to do this to install arches-for-science from the git repo.

WORKDIR ${APP_ROOT}

RUN apt -y install openssh-client
RUN mkdir -p /root/.ssh/ && \
    ssh-keygen -q -t rsa -N '' -f /root/.ssh/id_rsa && \
    chmod -R 600 /root/.ssh/ && \
    ssh-keyscan -t rsa github.com >> ~/.ssh/known_hosts


RUN git config --global url."https://github.com/".insteadOf git@github.com:
RUN git config --global url."https://".insteadOf git://
RUN git config --global url."https://github.com/".insteadOf ssh@github.com:
RUN git config --global url."https://".insteadOf ssh://
RUN git config --global http.postBuffer 524288000
RUN git config --global http.lowSpeedLimit 0
RUN git config --global http.lowSpeedTime 999999 



# Install our desired branch of Arches for Science

WORKDIR ${ARCHES_ROOT}
ARG AFS_CLONE
RUN echo "Install Arches for Science..."
# RUN git clone https://github.com/archesproject/arches-for-science.git
RUN git clone ${AFS_CLONE};

WORKDIR ${AFS_REPO_DIR}
RUN echo "git checkout ${AFS_GIT_BRANCH}";
RUN git checkout ${AFS_GIT_BRANCH};
RUN pip install -e .

# copy in settings with AFS special stuff to our newly created Arches project.
WORKDIR ${APP_ROOT}
# This is a hack to get settings_utils.py into the correct spot
# RUN cp ${ARCHES_REPO}/arches/settings_utils.py $SETTINGS_UTILS_PATH

COPY ./arches/settings.py ${SETTINGS_PATH}
RUN sed -i 's/\r$//g' ${SETTINGS_PATH}
# copy in local settings to our newly created Arches project.
COPY ./arches/settings_local.py ${SETTINGS_LOCAL_PATH}
RUN sed -i 's/\r$//g' ${SETTINGS_LOCAL_PATH}
# copy the celery.py file into out archaes project. This hopefully makes the workers and beat work:
COPY ./arches/celery.py ${CELERY_PATH}
RUN sed -i 's/\r$//g' ${CELERY_PATH}
# copy the urls.py into our new Arches project. This is part of
# customization for AFS
COPY ./arches/urls.py ${URLS_PATH}
RUN sed -i 's/\r$//g' ${URLS_PATH}
# Copy customized package information to the new Arches/AFS
COPY ./arches/package.json ${PACKAGE_PATH}

# copy the celery supervisor
COPY /arches/conf.d/ ${APP_ROOT}/conf.d/
COPY /arches/afs_plocal-supervisor.conf ${APP_ROOT}/${ARCHES_PROJECT}-supervisor.conf
RUN chmod -R 700 ${APP_ROOT}/${ARCHES_PROJECT}-supervisor.conf
RUN mkdir -p /var/log/supervisor
RUN mkdir -p /var/log/celery


WORKDIR ${APP_ROOT}
RUN echo "NPM install....";
RUN npm install

# Make sure the entry point is available and lacks weird characters
# that don't work in a Linux OS
COPY /arches/entrypoint.sh ${APP_ROOT}/entrypoint.sh
RUN chmod -R 700 ${APP_ROOT}/entrypoint.sh &&\
  dos2unix ${APP_ROOT}/entrypoint.sh

# A major security issue, but this is meant for a local deployment
WORKDIR ${APP_ROOT}
RUN chmod +x entrypoint.sh

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
