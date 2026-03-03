FROM ubuntu:22.04.5
# Start with Ubuntu 22

USER root

# Do the apt installation also install git
RUN apt-get update && apt-get install -y --no-install-recommends software-properties-common
RUN add-apt-repository universe
RUN apt-get update && apt-get install -y --no-install-recommends \
    python3.13 \
    python3.13-dev \
    python3.13-venv \
    python3-pip \
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

FROM python:3.13
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

# Get the Arches version for pip installation
ARG ARCHES_PIP_VERSION

# settings_local.py provides the DB credentials, etc. to the Arches project.
ENV SETTINGS_PATH=${APP_COMP_FOLDER}/settings.py
ENV SETTINGS_LOCAL_PATH=${APP_COMP_FOLDER}/settings_local.py
ENV CELERY_PATH=${APP_COMP_FOLDER}/celery.py
ENV URLS_PATH=${APP_COMP_FOLDER}/urls.py
ENV ARCHES_DATA=${ARCHES_ROOT}/arches_data
ENV PACKAGE_PATH=${APP_ROOT}/package.json
ENV PACKAGE_COMP_PATH=${APP_COMP_FOLDER}/package.json
ENV WHEELS=/wheels
ENV PYTHONUNBUFFERED=1
ENV PYTHONDONTWRITEBYTECODE 1

# Setup needed directories
RUN mkdir ${ARCHES_ROOT} && mkdir /var/log/supervisor && mkdir /var/log/celery

# Get ready to do some code installation
RUN apt-get update && apt-get install -y --no-install-recommends make lsb-release

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
        python3-dev \
        postgresql-client-14 \
        dos2unix \
        gettext \
    " \
    && apt-get install -y --no-install-recommends curl lsb-release gnupg \
    && curl -sL https://deb.nodesource.com/setup_16.x | bash - \
    && curl -sL https://www.postgresql.org/media/keys/ACCC4CF8.asc | gpg --dearmor -o /usr/share/keyrings/postgresql.gpg \
    && echo "deb [signed-by=/usr/share/keyrings/postgresql.gpg] http://apt.postgresql.org/pub/repos/apt/ $(lsb_release -sc)-pgdg main" > /etc/apt/sources.list.d/pgdg.list \
    && apt-get update -y \
    && apt-get install -y "wait-for-it" \
    && apt-get install -y nano \
    && apt-get install -y --no-install-recommends $RUN_DEPS



# ----------------------------------------------
# Do installs relating to yarn
# ----------------------------------------------

# Set environment variables
ENV NODE_MAJOR=20

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
    && pip install --no-cache-dir --no-input setuptools \
    && pip install --no-cache-dir --no-input arches==7.6.20 \
    && pip install --no-cache-dir --no-input python-docx==1.1.0


# Install the HER software and the working v7 branch
# for the Arches HER repo
ENV HER_REPO_PATH=${ARCHES_ROOT}/arches_her
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
COPY ./arches/package.json ${PACKAGE_COMP_PATH}

# copy the celery supervisor
COPY /arches/conf.d/ ${APP_ROOT}/conf.d/
RUN chmod -R 700 ${APP_ROOT}/conf.d/
COPY /arches/arches_megaj-supervisor.conf ${APP_ROOT}/arches_megaj-supervisor.conf
RUN chmod -R 700 ${APP_ROOT}/arches_megaj-supervisor.conf
RUN mkdir -p /var/log/supervisor
RUN mkdir -p /var/log/celery

# Make sure the entry point is available and lacks weird characters
# that don't work in a Linux OS
COPY /arches/entrypoint.sh ${APP_ROOT}/entrypoint.sh
RUN chmod -R 700 ${APP_ROOT}/entrypoint.sh &&\
  dos2unix ${APP_ROOT}/entrypoint.sh


# Set default workdir
WORKDIR ${APP_ROOT}

# So we can load packages
RUN mkdir -p ${APP_COMP_FOLDER}/templates/views/components/cards
RUN mkdir -p ${APP_COMP_FOLDER}/templates/views/components/datatypes
RUN mkdir -p ${APP_COMP_FOLDER}/templates/views/components/functions
RUN mkdir -p ${APP_COMP_FOLDER}/templates/views/components/plugins
RUN mkdir -p ${APP_COMP_FOLDER}/templates/views/components/reports
RUN mkdir -p ${APP_COMP_FOLDER}/templates/views/components/search
RUN mkdir -p ${APP_COMP_FOLDER}/templates/views/components/widgets
RUN mkdir -p ${APP_COMP_FOLDER}/templates/views/components/workflows
RUN mkdir -p ${APP_COMP_FOLDER}/media/js/views/components/widgets

WORKDIR ${APP_ROOT}
RUN mkdir -p ${APP_COMP_FOLDER}/templates
RUN chmod -R 744 ${APP_COMP_FOLDER}/templates
RUN mkdir -p ${APP_COMP_FOLDER}/media
RUN chmod -R 744 ${APP_COMP_FOLDER}/media
# RUN mkdir -p ${APP_COMP_FOLDER}/webpack
# RUN chmod -R 744 ${APP_COMP_FOLDER}/webpack


# Copy template files from the package
RUN echo "Copy HER templates and media to project";
# RUN	cp -rn  ${HER_REPO_PATH}/arches_her/templates/* ${APP_COMP_FOLDER}/templates/
RUN	cp -rn  ${HER_REPO_PATH}/arches_her/media/* ${APP_COMP_FOLDER}/media/
# RUN	cp -rn  ${HER_REPO_PATH}/webpack/* ${APP_COMP_FOLDER}/webpack/

# Modify the HER package for MEGA-J
RUN echo "Update the HER package for MEGA-J";
RUN echo "Update the HER ontology files for MEGA-J";
# Delete an older version of the CRMsci ontology.
RUN rm -rf ${HER_REPO_PATH}/arches_her/pkg/ontologies/cidoc_crm/CRMsci_v1.2.3.rdfs.xml
COPY /arches/megaj_pkg/ontologies/AAAo_v2.0.1.rdf ${HER_REPO_PATH}/arches_her/pkg/ontologies/cidoc_crm/AAAo_v2.0.1.rdf
COPY /arches/megaj_pkg/ontologies/CRMsci_v2.0.rdf ${HER_REPO_PATH}/arches_her/pkg/ontologies/cidoc_crm/CRMsci_v2.0.rdf
COPY /arches/megaj_pkg/ontologies/ontology_config.json ${HER_REPO_PATH}/arches_her/pkg/ontologies/cidoc_crm/ontology_config.json

RUN echo "Update the HER RDM files for MEGA-J";
COPY /arches/megaj_pkg/reference_data/concepts/d_activity_types.xml ${HER_REPO_PATH}/arches_her/pkg/reference_data/concepts/d_activity_types.xml
COPY /arches/megaj_pkg/reference_data/concepts/d_condition_rating.xml ${HER_REPO_PATH}/arches_her/pkg/reference_data/concepts/d_condition_rating.xml
COPY /arches/megaj_pkg/reference_data/concepts/d_disturbances.xml ${HER_REPO_PATH}/arches_her/pkg/reference_data/concepts/d_disturbances.xml
COPY /arches/megaj_pkg/reference_data/concepts/d_element_types.xml ${HER_REPO_PATH}/arches_her/pkg/reference_data/concepts/d_element_types.xml
COPY /arches/megaj_pkg/reference_data/concepts/d_geometry_source.xml ${HER_REPO_PATH}/arches_her/pkg/reference_data/concepts/d_geometry_source.xml
COPY /arches/megaj_pkg/reference_data/concepts/d_legal_violations.xml ${HER_REPO_PATH}/arches_her/pkg/reference_data/concepts/d_legal_violations.xml
COPY /arches/megaj_pkg/reference_data/concepts/d_management_recc_priorities.xml ${HER_REPO_PATH}/arches_her/pkg/reference_data/concepts/d_management_recc_priorities.xml
COPY /arches/megaj_pkg/reference_data/concepts/d_management_recommendations.xml ${HER_REPO_PATH}/arches_her/pkg/reference_data/concepts/d_management_recommendations.xml
COPY /arches/megaj_pkg/reference_data/concepts/d_monitoring_event_types.xml ${HER_REPO_PATH}/arches_her/pkg/reference_data/concepts/d_monitoring_event_types.xml
COPY /arches/megaj_pkg/reference_data/concepts/d_offices.xml ${HER_REPO_PATH}/arches_her/pkg/reference_data/concepts/d_offices.xml
COPY /arches/megaj_pkg/reference_data/concepts/d_ownership.xml ${HER_REPO_PATH}/arches_her/pkg/reference_data/concepts/d_ownership.xml
COPY /arches/megaj_pkg/reference_data/concepts/d_recc_future_monitoring_schedule.xml ${HER_REPO_PATH}/arches_her/pkg/reference_data/concepts/d_recc_future_monitoring_schedule.xml
COPY /arches/megaj_pkg/reference_data/concepts/d_review_status.xml ${HER_REPO_PATH}/arches_her/pkg/reference_data/concepts/d_review_status.xml
COPY /arches/megaj_pkg/reference_data/concepts/d_site_description_type.xml ${HER_REPO_PATH}/arches_her/pkg/reference_data/concepts/d_site_description_type.xml
COPY /arches/megaj_pkg/reference_data/concepts/d_threat_rating.xml ${HER_REPO_PATH}/arches_her/pkg/reference_data/concepts/d_threat_rating.xml
COPY /arches/megaj_pkg/reference_data/concepts/d_threats.xml ${HER_REPO_PATH}/arches_her/pkg/reference_data/concepts/d_threats.xml
COPY /arches/megaj_pkg/reference_data/concepts/d_topography.xml ${HER_REPO_PATH}/arches_her/pkg/reference_data/concepts/d_topography.xml

COPY /arches/megaj_pkg/reference_data/collections/collections.xml ${HER_REPO_PATH}/arches_her/pkg/reference_data/collections/collections.xml

RUN echo "Update the HER RDM files for MEGA-J";
RUN rm -rf ${HER_REPO_PATH}/arches_her/pkg/graphs/resource_models/*.json
COPY /arches/megaj_pkg/graphs/resource_models/Activity.json ${HER_REPO_PATH}/arches_her/pkg/graphs/resource_models/Activity.json
COPY /arches/megaj_pkg/graphs/resource_models/Area.json ${HER_REPO_PATH}/arches_her/pkg/graphs/resource_models/Area.json
COPY /arches/megaj_pkg/graphs/resource_models/Artefact.json ${HER_REPO_PATH}/arches_her/pkg/graphs/resource_models/Artefact.json
COPY ["/arches/megaj_pkg/graphs/resource_models/Bibliographic Source.json", "${HER_REPO_PATH}/arches_her/pkg/graphs/resource_models/Bibliographic Source.json"]
COPY ["/arches/megaj_pkg/graphs/resource_models/Digital Object.json", "${HER_REPO_PATH}/arches_her/pkg/graphs/resource_models/Digital Object.json"]
COPY ["/arches/megaj_pkg/graphs/resource_models/Monitoring Event.json", "${HER_REPO_PATH}/arches_her/pkg/graphs/resource_models/Monitoring Event.json"]
COPY /arches/megaj_pkg/graphs/resource_models/Organization.json ${HER_REPO_PATH}/arches_her/pkg/graphs/resource_models/Organization.json
COPY /arches/megaj_pkg/graphs/resource_models/Period.json ${HER_REPO_PATH}/arches_her/pkg/graphs/resource_models/Period.json
COPY /arches/megaj_pkg/graphs/resource_models/Person.json ${HER_REPO_PATH}/arches_her/pkg/graphs/resource_models/Person.json
COPY /arches/megaj_pkg/graphs/resource_models/Place.json ${HER_REPO_PATH}/arches_her/pkg/graphs/resource_models/Place.json
COPY ["/arches/megaj_pkg/graphs/resource_models/Site Element.json", "${HER_REPO_PATH}/arches_her/pkg/graphs/resource_models/Site Element.json"]
COPY /arches/megaj_pkg/graphs/resource_models/Site.json ${HER_REPO_PATH}/arches_her/pkg/graphs/resource_models/Site.json
COPY ["/arches/megaj_pkg/graphs/resource_models/Survey Area.json", "${HER_REPO_PATH}/arches_her/pkg/graphs/resource_models/Survey Area.json"]



# This is a hack to install SSH keys inside the container. Don't use
# these for anything other than cloning public git repos, since they
# are not secure within the docker image. But we seem to need this to
# access github in the npm install process.
WORKDIR ${APP_ROOT}

# This is a hack to install SSH keys inside the container. Don't use
# these for anything other than cloning public git repos, since they
# are not secure within the docker image. But we seem to need this to
# access github in the npm install process.
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
RUN rm -rf node_modules package-lock.json 
RUN npm install

# Now set up the entrypoint and run it.
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