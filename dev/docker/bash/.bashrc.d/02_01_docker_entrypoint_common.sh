#!/bin/bash

set -e

source "/opt/bash_libs/import_libs.sh"
BRC_DOCKER_ENTRYPOINT_COMMON_SH_S_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
lib_guard "BRC_DOCKER_ENTRYPOINT_COMMON_SH_S_DIR" || { return 0 2>/dev/null || exit 0; }


function docker_entrypoint_common {
  run_dpm_hook "before_entrypoint"
  "$@"
  return $?
}

