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

  # Ottieni il GID del socket Docker se montato
  if [ -S /var/run/docker.sock ]; then
      DOCKER_SOCK_GID=$(stat -c '%g' /var/run/docker.sock)

      # Crea un gruppo con lo stesso GID se non esiste
      if ! getent group $DOCKER_SOCK_GID > /dev/null; then
          groupadd -g $DOCKER_SOCK_GID dockerhost
      fi

      # Aggiungi l'utente al gruppo
      usermod -aG $DOCKER_SOCK_GID devuser
  fi
#execute workspace setup script
  run_script_if_available "/workdir/dev/scripts/setup.sh"

  #run user command
 "$@"
}