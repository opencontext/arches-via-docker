#!/bin/sh

cd /action_dir
echo "Start Arches Webpack via Docker"
echo "docker compose run oc run_worker"
docker compose run arches run_webpack