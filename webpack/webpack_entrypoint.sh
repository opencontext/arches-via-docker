#! /bin/bash
APP_FOLDER=${APP_ROOT}
APP_COMP_FOLDER=${APP_COMP_FOLDER}
run_webpack() {
	echo ""
	echo "----- *** RUNNING WEBPACK DEVELOPMENT SERVER *** -----"
	echo ""
	if [[ ${BUILD_PRODUCTION} == 'True' ]]; then
		# NOTE: Only do this if you have more than 8GB of system RAM. This will likely error out
		# otherwise.
		echo "Running Webpack, hopefully the build_production thing will work!"
		cd ${APP_FOLDER}
		exec sh -c "yarn install && wait-for-it arches:8000 -t 1200 && python3 manage.py build_production"
	else
		cd ${APP_COMP_FOLDER}
		echo "Running Webpack to do the yarn build_development thing."
		exec sh -c "yarn install && wait-for-it arches:8000 -t 1200 && yarn build_development"
		echo "Build development done. Now collectstatic."
		cd ${APP_FOLDER}
		python3 manage.py collectstatic --noinput
	fi
}

run_webpack