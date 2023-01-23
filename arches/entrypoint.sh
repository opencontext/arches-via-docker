#!/bin/bash

# APP and YARN folder locations
APP_FOLDER=${APP_ROOT}
APP_COMP_FOLDER=${APP_COMP_FOLDER}

YARN_MODULES_FOLDER=${APP_COMP_FOLDER}/$(awk \
	-F '--install.modules-folder' '{print $2}' ${APP_COMP_FOLDER}/.yarnrc \
	| awk '{print $1}' \
	| tr -d $'\r' \
	| tr -d '"' \
	| sed -e "s/^\.\///g")

# Environmental Variables
export DJANGO_PORT=${DJANGO_PORT:-8000}
COUCHDB_URL="http://$COUCHDB_USER:$COUCHDB_PASS@$COUCHDB_HOST:$COUCHDB_PORT"

#Utility functions that check db status
wait_for_db() {
	echo "Testing if database server is up..."
	while [[ ! ${return_code} == 0 ]]
	do
        psql --host=${PGHOST} --port=${PGPORT} --user=${PGUSERNAME} --dbname=postgres -c "select 1" >&/dev/null
		return_code=$?
		sleep 1
	done
	echo "Database server is up"

    echo "Testing if Elasticsearch is up..."
    while [[ ! ${return_code} == 0 ]]
    do
        curl -s "http://${ESHOST}:${ESPORT}/_cluster/health?wait_for_status=green&timeout=60s" >&/dev/null
        return_code=$?
        sleep 1
    done
    echo "Elasticsearch is up"
}

db_exists() {
	echo "Checking if database "${PGDBNAME}" exists..."
	count=`psql --host=${PGHOST} --port=${PGPORT} --user=${PGUSERNAME} --dbname=postgres -Atc "SELECT COUNT(*) FROM pg_catalog.pg_database WHERE datname='${PGDBNAME}'"`

	# Check if returned value is a number and not some error message
	re='^[0-9]+$'
	if ! [[ ${count} =~ $re ]] ; then
	   echo "Error: Something went wrong when checking if database "${PGDBNAME}" exists..." >&2;
	   echo "Exiting..."
	   exit 1
	fi

	# Return 0 (= true) if database exists
	if [[ ${count} > 0 ]]; then
		return 0
	else
		return 1
	fi
}

#### Install
init_arches() {
	echo "Checking if Arches project "${ARCHES_PROJECT}" exists..."
	if [[ ! -d ${APP_FOLDER} ]] || [[ ! "$(ls ${APP_FOLDER})" ]]; then
		echo ""
		echo "----- Custom Arches project '${ARCHES_PROJECT}' does not exist. -----"
		echo "----- Creating '${ARCHES_PROJECT}'... -----"
		echo ""

		cd ${APP_FOLDER}
		echo "Sleep for a 20 seconds because elastic search seems to need the wait (a total hack)..."
		sleep 20s;
		arches-project create ${ARCHES_PROJECT}
		run_setup_db
		setup_couchdb

		exit_code=$?
		if [[ ${exit_code} != 0 ]]; then
			echo "Something went wrong when creating your Arches project: ${ARCHES_PROJECT}."
			echo "Exiting..."
			exit ${exit_code}
		fi
	else
		echo "Custom Arches project '${ARCHES_PROJECT}' exists."
		wait_for_db
		if db_exists; then
			echo "Database ${PGDBNAME} already exists."
			echo "Skipping Package Loading"
		else
			echo "Database ${PGDBNAME} does not exists yet."
			run_setup_db
			run_migrations
			# run_load_package #change to run_load_package if preferred
			setup_couchdb
		fi
	fi
}

# Setup Couchdb (when should this happen?)
setup_couchdb() {
    echo "--- SKIP Running: Creating couchdb system databases ---"
    # curl -X PUT ${COUCHDB_URL}/_users
    # curl -X PUT ${COUCHDB_URL}/_global_changes
    # curl -X PUT ${COUCHDB_URL}/_replicator
}

# Yarn
install_yarn_components() {
	echo "Check to see if Yarn modules exist..."
	if [[ ! -d ${YARN_MODULES_FOLDER} ]] || [[ ! "$(ls ${YARN_MODULES_FOLDER})" ]]; then
		echo "Yarn modules do not exist, installing..."
		cd ${APP_COMP_FOLDER}
		yarn build_development
	else
		echo "Yarn modules seem to exist:"
		echo "---------------------------------------------------------------"
		cd ${YARN_MODULES_FOLDER}
		ls
		echo "---------------------------------------------------------------"
	fi
}

#### Misc
check_settings_local() {
	# Make sure we have a settings_local in the proper location of the project

	# Skip this, this happens with the docker container build.
	# echo "Copying ${APP_FOLDER}/settings_local.py to ${APP_FOLDER}/${ARCHES_PROJECT}/settings_local.py..."
	# cp -n ${APP_FOLDER}/settings_local.py ${APP_FOLDER}/${ARCHES_PROJECT}/settings_local.py

	cd ${APP_COMP_FOLDER}
	echo "The directory ${APP_COMP_FOLDER} contains:"
	ls
	echo "---------------------------------------------------------------"
}

#### Run commands

start_celery_supervisor() {
	cd ${APP_FOLDER}
	supervisord -c arches-supervisor.conf
}

run_createcachetable() {
	echo ""
	echo "----- RUNNING CREATE CACHETABLE -----"
	echo ""
	cd ${APP_FOLDER}
	python3 manage.py createcachetable
}

run_make_migrations() {
	echo ""
	echo "----- RUNNING DATABASE MAKE MIGRATIONS -----"
	echo ""
	cd ${APP_FOLDER}
	python3 manage.py makemigrations
}

run_elastic_safe_migrations() {
	echo ""
	echo "----- RUNNING DATABASE MIGRATIONS WITH ELASTIC CHECK -----"
	echo ""
	echo "Testing if Elasticsearch is up..."
    while [[ ! ${return_code} == 0 ]]
    do
        curl -s "http://${ESHOST}:${ESPORT}/_cluster/health?wait_for_status=green&timeout=60s" >&/dev/null
        return_code=$?
        sleep 1
    done
    echo "Elasticsearch is up"
	cd ${APP_FOLDER}
	# echo "Run the server for a few seconds..."
	# python3 manage.py runserver --noreload
	echo "Sleep for a 20 seconds because elastic search seems to need the wait (a total hack)..."
	sleep 20s;
	echo "Now do Migrations..."
	python3 manage.py migrate
}

run_migrations() {
	echo ""
	echo "----- RUNNING DATABASE MIGRATIONS -----"
	echo ""
	cd ${APP_FOLDER}
	python3 manage.py migrate
}

run_collect_static() {
	echo ""
	echo "----- RUNNING COLLECT STATIC -----"
	echo ""
	if [[ ${BUILD_PRODUCTION} == 'True' ]]; then
		echo "Skipping collectstatic, hopefully buildproduction will do the trick..."
	else
		cd ${APP_FOLDER}
		python3 manage.py collectstatic --noinput
	fi
	echo "---------------------------------------------------------------"
}

run_collect_static_nocheck() {
	echo ""
	echo "----- RUNNING COLLECT STATIC -----"
	echo ""
	cd ${APP_FOLDER}
	python3 manage.py collectstatic --noinput
	echo "---------------------------------------------------------------"
}

run_build_production() {
	echo ""
	echo "----- RUNNING BUILD PRODUCTION -----"
	echo ""
	if [[ ${BUILD_PRODUCTION} == 'True' ]]; then
		cd ${APP_FOLDER}
		python3 manage.py build_production
	else
		echo "Skipping buildproduction because BUILD_PRODUCTION is not 'True' "
	fi
	echo "---------------------------------------------------------------"
}

run_list_static() {
	echo ""
	echo "----- VIEW COLLECTED STATIC -----"
	echo ""
	cd /static_root
	ls
	echo "---------------------------------------------------------------"
}

run_setup_db() {
	echo ""
	echo "----- RUNNING SETUP_DB -----"
	echo ""
	cd ${APP_FOLDER}
	python3 manage.py setup_db --force
}

run_load_package() {
	echo ""
	echo "----- *** LOADING PACKAGE: ${ARCHES_PROJECT} *** -----"
	echo ""
	cd ${APP_FOLDER}
	python3 manage.py packages -o load_package -s ${ARCHES_PROJECT}/pkg -db -dev -y
}

run_django_server() {
	echo ""
	echo "----- *** RUNNING DJANGO DEVELOPMENT SERVER *** -----"
	echo ""
	cd ${APP_FOLDER}
	if [[ ${DJANGO_DEBUG} == 'True' ]]; then
		echo "Running DEBUG mode Django"
		exec sh -c "python3 manage.py runserver 0.0.0.0:${DJANGO_PORT}"
	else
		echo "Should run the production mode Arches Django via gunicorn via:"
		echo "gunicorn -w 2 -b 0.0.0.0:${DJANGO_PORT} ${ARCHES_PROJECT}.wsgi:application --reload --timeout 3600"
		exec sh -c "gunicorn -w 2 -b 0.0.0.0:${DJANGO_PORT} ${ARCHES_PROJECT}.wsgi:application --reload --timeout 3600"
		# echo "But, since I can get gunicorn to work yet, running via Django"
		# exec sh -c "python3 manage.py runserver 0.0.0.0:${DJANGO_PORT}"
	fi
}

#### Main commands
run_arches() {
	init_arches
	run_elastic_safe_migrations
	run_elastic_safe_migrations
	# run_createcachetable
	# run_collect_static
	run_django_server
	# run_build_production
	# install_yarn_components
}

#### Main commands
run_livereload() {
	run_livereload_server
}

### Starting point ###

# trying not to use virtualenv???
# activate_virtualenv

# Use -gt 1 to consume two arguments per pass in the loop
# (e.g. each argument has a corresponding value to go with it).
# Use -gt 0 to consume one or more arguments per pass in the loop
# (e.g. some arguments don't have a corresponding value to go with it, such as --help ).

# If no arguments are supplied, assume the server needs to be run
if [[ $#  -eq 0 ]]; then
	start_celery_supervisor
	wait_for_db
	run_arches
fi

# Else, process arguments
echo "Full command: $@"
while [[ $# -gt 0 ]]
do
	key="$1"
	echo "Command: ${key}"

	case ${key} in
		run_arches)
			start_celery_supervisor
			check_settings_local
			wait_for_db
			run_arches
		;;
		run_livereload)
			run_livereload_server
		;;
		run_collect_static)
			run_collect_static
		;;
		run_collect_static_nocheck)
			run_collect_static_nocheck
		;;
		run_list_static)
			run_list_static
		;;
		run_build_production)
			run_build_production
		;;
		setup_arches)
			start_celery_supervisor
			check_settings_local
			wait_for_db
			setup_arches
		;;
		run_tests)
			check_settings_local
			wait_for_db
			run_tests
		;;
		run_migrations)
		    check_settings_local
			wait_for_db
			run_migrations
		;;
		install_yarn_components)
			install_yarn_components
		;;
		help|-h)
			display_help
		;;
		*)
            cd ${APP_FOLDER}
			"$@"
			exit 0
		;;
	esac
	shift # next argument or value
done
