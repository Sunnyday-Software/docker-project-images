#!/bin/bash

source "/opt/bash_libs/import_libs.sh"
BRC_UTILS_SH_S_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
lib_guard "BRC_UTILS_SH_S_DIR" || { return 0 2>/dev/null || exit 0; }


# Esegue uno script se esiste ed è accessibile.
#
# Questa funzione verifica l'esistenza e l'eseguibilità di uno script al percorso specificato.
# Se lo script esiste ma non è eseguibile, la funzione tenta di renderlo eseguibile tramite chmod
# prima di eseguirlo. Se lo script non viene trovato, viene stampato un messaggio di errore su stderr.
#
# Parametri:
#   script_path - Il percorso completo dello script da eseguire
#
# Comportamento:
#   - Se lo script esiste ed è già eseguibile, viene eseguito immediatamente
#   - Se lo script esiste ma non è eseguibile, viene reso eseguibile con chmod +x e poi eseguito
#   - Se lo script non esiste, viene stampato un messaggio di errore su stderr e la funzione termina
#
# Codici di ritorno:
#   Restituisce il codice di uscita dello script eseguito, oppure 0 se lo script non viene trovato
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

  log_err "Script non eseguito: script non trovato in ${script_path}"
}

