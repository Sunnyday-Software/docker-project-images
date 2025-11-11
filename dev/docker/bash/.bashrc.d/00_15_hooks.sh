#!/bin/bash

source "/opt/bash_libs/import_libs.sh"
BRC_HOOKS_SH_S_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
lib_guard "BRC_HOOKS_SH_S_DIR" || { return 0 2>/dev/null || exit 0; }

run_dpm_hook() {
  # serve sia il file sia il nome
  if [[ -z "${DPM_HOOKS_FILE:-}" || -z "${DPM_HOOK_NAME:-}" ]]; then
    return 0
  fi

  local hook_id="$1"   # es: "entrypoint", "before-cmd", ...
  shift                 # da qui in poi ci sono gli argomenti extra

  # risolvo il path relativo alla root del progetto
  local hooks_path="${DPM_PROJECT_ROOT%/}/${DPM_HOOKS_FILE}"

  if [[ ! -f "$hooks_path" ]]; then
    log_warn "dpm hook: file non trovato: $hooks_path"
    return 0
  fi

  # chiamata:
  # 1) DPM_HOOK_NAME  (chi è il servizio/container)
  # 2) hook_id        (quale fase)
  # 3...) extra params passati a run_dpm_hook
  "$hooks_path" "${DPM_HOOK_NAME}" "${hook_id}" "$@"
}
