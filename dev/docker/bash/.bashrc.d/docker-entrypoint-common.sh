#!/bin/bash

set -e

function docker-entrypoint-common {
# Source all Bash files in the commons_functions directory
. ~/.bashrc.d/load.sh

if [ "$(id -u)" = '0' ]; then
  # then restart script as bashuser user
	exec gosu bashuser "$BASH_SOURCE" "$@"
else
  exec "$@"
fi
}