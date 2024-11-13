#!/bin/sh

cd /workdir
echo "Start Arches Webpack via Docker"
echo "docker compose run arches run_webpack"
# exec docker compose exec --no-TTY arches ./entrypoint.sh run_setup_webpack