#!/bin/bash

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

# Set up the trap to catch errors
trap 'error_handler ${LINENO} "$BASH_COMMAND" $?' ERR

# Set -e to exit on error
set -e
