#!/usr/bin/dumb-init /usr/bin/bash

# https://github.com/Yelp/dumb-init

set -eo pipefail

# Trap per cleanup
cleanup() {
    echo "Cleaning up..."
    # Cleanup operations
}
trap cleanup EXIT INT TERM


# Prevent core dumps
ulimit -c 0

. ~/.bashrc.d/docker-entrypoint-common.sh
docker_entrypoint_common "$@"