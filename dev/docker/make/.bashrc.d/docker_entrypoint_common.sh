#!/bin/bash

set -euo pipefail

# Funzione estratta per incapsulare la logica di esecuzione condizionata
function run_script_if_available() {
  local script_path="$1"

  if [[ -f "${script_path}" && -x "${script_path}" ]]; then
    "${script_path}"
    return
  fi

  if [[ -f "${script_path}" && ! -x "${script_path}" ]]; then
    # Rende eseguibile e poi esegue
    chmod +x "${script_path}"
    "${script_path}"
    return
  fi

  echo "Script non eseguito: script non trovato in ${script_path}" >&2
}

function docker_entrypoint_common {
# Source all Bash files in the commons_functions directory
. ~/.bashrc.d/load.sh
#execute workspace setup script
  run_script_if_available "/workdir/dev/scripts/setup.sh"

  #run user command
  exec "$@"
}