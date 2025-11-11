#!/usr/bin/env bash

# Scopo: inizializzare git nel container usando le variabili DPM_*.
# Nota: NON crea/scrive credential store: le credenziali https vanno passate al momento del clone.


source "/opt/bash_libs/import_libs.sh"
BRC_GIT_BOOTSTRAP_SH_S_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
lib_guard "BRC_GIT_BOOTSTRAP_SH_S_DIR" || { return 0 2>/dev/null || exit 0; }


log_debug_section "git-bootstrap"

# ===== INPUT ATTESI =====
# identità
GIT_NAME="${DPM_GIT_USER_NAME:-}"
GIT_EMAIL="${DPM_GIT_USER_EMAIL:-}"

# host git per eventuale conversione ssh → https
GIT_HOST="${DPM_GIT_HTTP_HOST:-github.com}"

# base config
SAFE_HOME="${HOME:-${HOME_DIR:-/root}}"
CONFIG_HOME="${XDG_CONFIG_HOME:-${SAFE_HOME}/.config}"

log_debug_env_var DPM_GIT_USER_NAME
log_debug_env_var DPM_GIT_USER_EMAIL
log_debug_env_var DPM_GIT_HTTP_HOST

# crea la dir config (soft)
mkdir -p "${CONFIG_HOME}/git" 2>/dev/null || true

# ===== CONFIG GIT DI BASE =====
if [[ -n "$GIT_NAME" ]]; then
  git config --global user.name "$GIT_NAME" 2>/dev/null || log_warn "git: impossibile impostare user.name"
fi
if [[ -n "$GIT_EMAIL" ]]; then
  git config --global user.email "$GIT_EMAIL" 2>/dev/null || log_warn "git: impossibile impostare user.email"
fi

# aggiungi ${DPM_PROJECT_ROOT} come safe.directory (tutti i progetti sono lì)
if ! git config --global --get-all safe.directory | grep -q "^${DPM_PROJECT_ROOT}$"; then
  git config --global --add safe.directory "${DPM_PROJECT_ROOT}" 2>/dev/null || true
fi

# ===== CONVERSIONE REMOTE ORIGIN (ssh → https) =====
if git -C "${DPM_PROJECT_ROOT}" rev-parse --is-inside-work-tree >/dev/null 2>&1; then
  current_url="$(git -C "${DPM_PROJECT_ROOT}" remote get-url origin 2>/dev/null || true)"
  if [[ -n "$current_url" && "$current_url" == git@"$GIT_HOST":* ]]; then
    https_url="${current_url/git@${GIT_HOST}:/https://${GIT_HOST}/}"
    git -C "${DPM_PROJECT_ROOT}" remote set-url origin "$https_url" 2>/dev/null \
      && log_info "git: origin convertito a HTTPS: $https_url" \
      || log_warn "git: impossibile aggiornare origin a HTTPS"
  fi
fi

log_info "git-bootstrap: configurazione base completata (senza credential store)"

log_end_section
