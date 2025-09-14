#!/bin/bash

set -e

function docker_entrypoint_common {
# Source all Bash files in the commons_functions directory
. ~/.bashrc.d/load.sh
  exec "$@"
}