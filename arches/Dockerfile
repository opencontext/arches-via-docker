# Build a working Arches for Open Context deployment from a dockerfile
FROM ubuntu:20.04 as base
USER root

## Setting default environment variables
ENV WEB_ROOT=/web_root
# Root project folder
ENV ARCHES_PROJECT=arches_proj
ENV ARCHES_ROOT=${WEB_ROOT}/arches
ENV APP_ROOT=${WEB_ROOT}/${ARCHES_PROJECT}
ENV WHEELS=/wheels
ENV PYTHONUNBUFFERED=1

RUN apt-get update && apt-get install -y make software-properties-common
RUN add-apt-repository ppa:deadsnakes/ppa

# Get the pre-built python wheels from the build environment
RUN mkdir ${WEB_ROOT}
RUN mkdir ${APP_ROOT}

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
        mime-support \
        libgdal-dev \
        python3-venv \
        postgresql-client-12 \
        python3.10 \
        python3.10-distutils \
        python3.10-venv \
        dos2unix \
    " \
    && apt-get install -y --no-install-recommends curl \
    && curl -sL https://deb.nodesource.com/setup_10.x | bash - \
    && curl -sL https://www.postgresql.org/media/keys/ACCC4CF8.asc | apt-key add - \
    && add-apt-repository "deb http://apt.postgresql.org/pub/repos/apt/ $(lsb_release -sc)-pgdg main" \
    && apt-get update -y \
    && apt-get install -y nano \
    && apt-get install -y --no-install-recommends $RUN_DEPS \
    && curl https://bootstrap.pypa.io/get-pip.py -o get-pip.py \
    && python3.10 get-pip.py \
    && apt-get install -y nodejs \
    && npm install -g yarn


WORKDIR ${WEB_ROOT}

RUN rm -rf /root/.cache/pip/*


# From here, run commands from ARCHES_ROOT
WORKDIR ${ARCHES_ROOT}
# Install the Arches application
RUN pip install arches

# Create the Arches project
RUN arches-project create ${ARCHES_PROJECT}

# copy in local settings
WORKDIR ${APP_ROOT}
COPY ./arches/settings_local.py /settings_local.py
RUN sed -i 's/\r$//g' /settings_local.py

RUN mkdir /var/log/supervisor
RUN mkdir /var/log/celery

# Make sure the entry point is available and lacks weird characters
# that don't work in a Linux OS
COPY /arches/entrypoint.sh ${APP_ROOT}/entrypoint.sh
RUN chmod -R 700 ${APP_ROOT}/entrypoint.sh &&\
  dos2unix ${APP_ROOT}/entrypoint.sh

# Set default workdir
WORKDIR ${APP_ROOT}
ENTRYPOINT ["./entrypoint.sh"]
CMD ["run_arches"]

# Expose port 8000
EXPOSE 8000
