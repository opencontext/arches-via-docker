#!/bin/sh

cd /workdir
echo "Start Arches Webpack via Docker"
echo "docker compose run arches run_webpack"
until nc -z arches 8000; do
	echo "Waiting for the arches server application to start..."
  	sleep 5s & wait ${!}
done
docker compose run arches run_webpack