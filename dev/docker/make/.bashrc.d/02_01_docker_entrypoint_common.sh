#!/bin/bash

set -e


function docker_entrypoint_common {
  echo "🚀 Running docker_entrypoint_common as $(whoami)"

  #execute workspace setup script
  run_script_if_available "/workdir/dev/scripts/setup.sh"

  #run user command
  "$@"
  return $?
}