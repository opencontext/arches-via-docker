# Build a working Arches for Open Context deployment from a dockerfile
FROM ubuntu:22.04 as base
USER root

## Setting default environment variables
ARG AFS_GIT_BRANCH
ARG ARCHES_GIT_BRANCH
# the directory where we will clone arches into
ARG ALL_ARCHES_ROOT
# the directory where the AFS repo will exist once cloned
ARG AFS_REPO
# the directory where the Arches repo will exist once cloned
ARG ARCHES_REPO
# The name of the arches project
ARG ARCHES_PROJECT
# Project specific paths
ARG APP_ROOT
ARG APP_COMP_FOLDER
ARG UPLOADED_FILES_FOLDER

# settings_local.py provides the DB credentials, etc. to the Arches project.
ENV SETTINGS_PATH=${APP_COMP_FOLDER}/settings.py
ENV SETTINGS_LOCAL_PATH=${APP_COMP_FOLDER}/settings_local.py
ENV SETTINGS_UTILS_PATH=${APP_COMP_FOLDER}/settings_utils.py
ENV CELERY_PATH=${APP_COMP_FOLDER}/celery.py
ENV URLS_PATH=${APP_COMP_FOLDER}/urls.py
ENV PACKAGE_PATH=${APP_COMP_FOLDER}/package.json
ENV ARCHES_DATA=${ALL_ARCHES_ROOT}/arches_data
ENV WHEELS=/wheels
ENV PYTHONUNBUFFERED=1
ENV PYTHONDONTWRITEBYTECODE 1

# Setup needed directories
RUN mkdir ${ALL_ARCHES_ROOT} && mkdir /var/log/supervisor && mkdir /var/log/celery

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
        python3.10 \
        python3.10-dev \
        python3.10-distutils \
        python3.10-venv \
        python3-pip \
        mime-support \
        libxml2-dev \
        libproj-dev \
        libjson-c-dev \
        libgdal-dev \
        libpq-dev \
        docbook-xsl \
        docbook-mathml \
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
    && apt-get install -y --no-install-recommends $RUN_DEPS \
    && apt-get install -y nodejs \
    && apt-get install -y git \
    && npm install -g yarn

# Cleam pip
RUN rm -rf /root/.cache/pip/*
RUN pip install --upgrade pip

# Install our desired branch of Arches
WORKDIR ${ALL_ARCHES_ROOT}
RUN echo "Install Arches..."
RUN git clone https://github.com/archesproject/arches.git

WORKDIR ${ARCHES_REPO}
RUN echo "git checkout ${ARCHES_GIT_BRANCH}";
RUN git checkout ${ARCHES_GIT_BRANCH};

RUN pip install -e . --user --no-use-pep517 && pip install -r arches/install/requirements.txt && pip install -r arches/install/requirements_dev.txt
# Install some other dependencies
RUN pip install supervisor && pip install Redis



WORKDIR ${ALL_ARCHES_ROOT}
# Try to install the project
RUN echo "Create a new Arches project: ${ARCHES_PROJECT}";
RUN python3 ${ARCHES_REPO}/arches/install/arches-project create ${ARCHES_PROJECT}
RUN mkdir -p ${UPLOADED_FILES_FOLDER}

# Install our desired branch of Arches for Science
WORKDIR ${ALL_ARCHES_ROOT}
RUN echo "Install Arches for Science..."
RUN git clone https://github.com/archesproject/arches-for-science.git

WORKDIR ${AFS_REPO}
RUN echo "git checkout ${AFS_GIT_BRANCH}";
RUN git checkout ${AFS_GIT_BRANCH};
RUN pip install -e .

# copy in settings with AFS special stuff to our newly created Arches project.
WORKDIR ${APP_ROOT}
# This is a hack to get settings_utils.py into the correct spot
RUN cp ${ARCHES_REPO}/arches/settings_utils.py $SETTINGS_UTILS_PATH

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
