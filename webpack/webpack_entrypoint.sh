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
		echo "yarn install && wait-for-it arches:8000 -t 1200 && $APP_COMP_FOLDER/yarn start && python3 $APP_FOLDER/manage.py build_production"
		cd ${APP_FOLDER}
		exec sh -c "yarn install && wait-for-it arches:8000 -t 1200 && $APP_COMP_FOLDER/yarn start && python3 $APP_FOLDER/manage.py build_production"
	else
		cd ${APP_COMP_FOLDER}
		echo "Running Webpack"
		exec sh -c "yarn install && wait-for-it arches:8000 -t 1200 && yarn start"
	fi
}

run_webpack