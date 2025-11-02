#!/bin/bash

set -e

function docker_entrypoint_common {
  "$@"
  return $?
}

