#! /bin/bash
APP_FOLDER=${APP_ROOT}
APP_COMP_FOLDER=${APP_COMP_FOLDER}
run_webpack() {
	echo ""
	echo "----- *** RUNNING WEBPACK DEVELOPMENT SERVER *** -----"
	echo ""
	if [[ ${BUILD_PRODUCTION} == 'True' ]]; then
		echo "Skipping Webpack, hopefully buildproduction will do the trick..."
		echo "So, doing the buildproduction thing..."
		cd ${APP_FOLDER}
		python3 manage.py build_production
	else
		cd ${APP_COMP_FOLDER}
		echo "Running Webpack"
		exec sh -c "yarn install && wait-for-it arches:8000 -t 1200 && yarn start"
	fi
}

run_webpack