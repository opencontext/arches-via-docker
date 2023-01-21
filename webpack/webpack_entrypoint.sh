#! /bin/bash
APP_FOLDER=${APP_ROOT}
APP_COMP_FOLDER=${APP_COMP_FOLDER}
run_webpack() {
	echo ""
	echo "----- *** RUNNING WEBPACK DEVELOPMENT SERVER *** -----"
	echo ""
	if [[ ${BUILD_PRODUCTION} == 'True' ]]; then
		echo "Running Webpack, hopefully the build_production thing will work!"
		cd ${APP_FOLDER}
		exec sh -c "yarn install && wait-for-it arches:8000 -t 1200 && python3 manage.py build_production"
		# exec sh -c "yarn install && wait-for-it arches:8000 -t 1200 && yarn build_production"
		# echo "Do the build_production thing"
		# cd ${APP_FOLDER}
		# python3 manage.py build_production
	else
		cd ${APP_COMP_FOLDER}
		echo "Running Webpack"
		exec sh -c "yarn install && wait-for-it arches:8000 -t 1200 && yarn start"
	fi
}

run_webpack