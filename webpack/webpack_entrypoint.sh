#!/bin/sh

cd /workdir
echo "Start Arches Webpack via Docker"
echo "docker compose run arches run_webpack"
until nc -z arches 8000; do
	echo "Waiting for the arches server application to start..."
  	sleep 5s & wait ${!}
done
exec docker compose exec --no-TTY arches ./entrypoint.sh run_setup_webpack