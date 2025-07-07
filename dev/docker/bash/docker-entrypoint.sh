#!/usr/bin/dumb-init /usr/bin/bash

# https://github.com/Yelp/dumb-init


# Error handling trap
error_handler() {
  local line=$1
  local command=$2
  local code=$3
  echo "--------------------------------------------------------------------------------"
  echo "❌ Error in $(basename "$0") at line $line"
  echo "❌ Command: $command"
  echo "❌ Expanded command: $(eval echo "$command" 2>/dev/null || echo "Could not expand command")"
  echo "❌ Exit code: $code"
  exit $code
}

# Funzione per loggare ed eseguire comandi
log_and_execute() {
    echo "🔍 [$(date '+%Y-%m-%d %H:%M:%S')] Executing: $*" >&2
    "$@"
    local exit_code=$?
    if [ $exit_code -eq 0 ]; then
        echo "✅ [$(date '+%Y-%m-%d %H:%M:%S')] Command succeeded" >&2
    else
        echo "❌ [$(date '+%Y-%m-%d %H:%M:%S')] Command failed with exit code: $exit_code" >&2
    fi
    return $exit_code
}


# Set up the trap to catch errors
trap 'error_handler ${LINENO} "$BASH_COMMAND" $?' ERR

set -e

# Prevent core dumps
ulimit -c 0

. ~/.bashrc.d/docker_entrypoint_common.sh

docker_entrypoint_common "$@"

