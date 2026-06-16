#!/bin/sh

cd /workdir
echo "Start Arches Webpack via Docker"
echo "docker compose run arches run_webpack"
until nc -z arches_megaj 8000; do
	echo "Waiting for the arches server application to start..."
  	sleep 5s & wait ${!}
done
exec docker compose exec --no-TTY arches_megaj ./entrypoint.sh run_setup_webpack