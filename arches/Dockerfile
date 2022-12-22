# Build a working Arches for Open Context deployment from a dockerfile
FROM ubuntu:20.04 as base
USER root

## Setting default environment variables
ENV WEB_ROOT=/web_root
ENV APP_ROOT=${WEB_ROOT}/arches_oc
# Root project folder
ENV ARCHES_ROOT=${WEB_ROOT}/arches
ENV WHEELS=/wheels
ENV PYTHONUNBUFFERED=1

RUN apt-get update && apt-get install -y make software-properties-common

# Get the pre-built python wheels from the build environment
RUN mkdir ${WEB_ROOT}

# Install packages required to run Arches
# Note that the ubuntu/debian package for libgdal1-dev pulls in libgdal1i, which is built
# with everything enabled, and so, it has a huge amount of dependancies (everything that GDAL
# support, directly and indirectly pulling in mysql-common, odbc, jp2, perl! ... )
# a minimised build of GDAL could remove several hundred MB from the container layer.
RUN set -ex \
    && RUN_DEPS=" \
        build-essential \
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

# copy in local settings
COPY ./arches/settings_local.py /settings_local.py
RUN sed -i 's/\r$//g' /settings_local.py

RUN mkdir /var/log/supervisor
RUN mkdir /var/log/celery

ENTRYPOINT ["tail", "-f", "/dev/null"]

# Expose port 8000
EXPOSE 8000
