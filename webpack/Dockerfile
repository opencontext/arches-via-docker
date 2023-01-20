FROM ubuntu:20.04 as base
USER root
## Setting default environment variables
ARG ARCHES_ROOT
# The name of the arches project
ARG ARCHES_PROJECT
# Project specific paths
ARG APP_ROOT
ARG APP_COMP_FOLDER

# Make sure we have the local settings copyied into here too
ENV SETTINGS_LOCAL_PATH=${APP_COMP_FOLDER}/settings_local.py
COPY ./arches/settings_local.py ${SETTINGS_LOCAL_PATH}

RUN mkdir -p ${APP_COMP_FOLDER}/webpack
RUN mkdir -p /ep_dir

RUN apt-get update && apt-get install -y make software-properties-common
RUN add-apt-repository ppa:deadsnakes/ppa
RUN set -ex \
  && apt-get update -y \
  && RUN_DEPS=" \
  build-essential \
  python3.8-dev \
  mime-support \
  libgdal-dev \
  python3-venv \
  python3.8 \
  python3.8-distutils \
  python3.8-venv \
  dos2unix \
  git \
  " \
  && apt-get install -y --no-install-recommends curl \
  && curl -sL https://deb.nodesource.com/setup_16.x | bash - \
  && curl -sL https://www.postgresql.org/media/keys/ACCC4CF8.asc | apt-key add - \
  && curl https://bootstrap.pypa.io/get-pip.py -o get-pip.py \
  && apt-get install -y --no-install-recommends $RUN_DEPS \
  && apt-get install -y "wait-for-it" \
  && apt-get install -y nano \
  && python3.8 get-pip.py \
  && apt-get install -y nodejs \
  && npm install -g yarn

RUN apt-get update && apt-get -y install curl \
  && curl -sL https://deb.nodesource.com/setup_16.x | bash - \
  && apt-get install nodejs && npm install -g yarn && apt install wait-for-it
RUN pip install --upgrade pip
RUN pip install supervisor && pip install arches

COPY /webpack/webpack_entrypoint.sh /ep_dir/webpack_entrypoint.sh
RUN chmod -R 700 /ep_dir/webpack_entrypoint.sh &&\
  dos2unix /ep_dir/webpack_entrypoint.sh
WORKDIR /ep_dir
ENTRYPOINT ["./webpack_entrypoint.sh"]
CMD ["run_webpack"]
EXPOSE 8021

EXPOSE 8080