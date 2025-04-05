#!/usr/bin/dumb-init /usr/bin/bash

# https://github.com/Yelp/dumb-init

set -e

# Prevent core dumps
ulimit -c 0

. ~/.bashrc.d/docker-entrypoint-common.sh
docker_entrypoint_common "$@"

