#!/usr/bin/env bash

# Scopo: inizializzare git nel container usando le variabili DPM_*.
# Nota: NON crea/scrive credential store: le credenziali https vanno passate al momento del clone.

# se è già stato eseguito (sourced più volte) esci soft
if [[ "${__GIT_BOOTSTRAP_DONE:-}" == "true" ]]; then
  log_debug "git-bootstrap: già eseguito, skip."
  return 0 2>/dev/null || exit 0
fi

log_debug_section "git-bootstrap"

# ===== INPUT ATTESI =====
# identità
GIT_NAME="${DPM_GIT_USER_NAME:-}"
GIT_EMAIL="${DPM_GIT_USER_EMAIL:-}"

# host git per eventuale conversione ssh → https
GIT_HOST="${DPM_GIT_HTTP_HOST:-github.com}"

# base config
SAFE_HOME="${HOME:-/root}"
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

# aggiungi /workdir come safe.directory (tutti i progetti sono lì)
if ! git config --global --get-all safe.directory | grep -q "^/workdir$"; then
  git config --global --add safe.directory /workdir 2>/dev/null || true
fi

# ===== CONVERSIONE REMOTE ORIGIN (ssh → https) =====
if git -C /workdir rev-parse --is-inside-work-tree >/dev/null 2>&1; then
  current_url="$(git -C /workdir remote get-url origin 2>/dev/null || true)"
  if [[ -n "$current_url" && "$current_url" == git@"$GIT_HOST":* ]]; then
    https_url="${current_url/git@${GIT_HOST}:/https://${GIT_HOST}/}"
    git -C /workdir remote set-url origin "$https_url" 2>/dev/null \
      && log_info "git: origin convertito a HTTPS: $https_url" \
      || log_warn "git: impossibile aggiornare origin a HTTPS"
  fi
fi

log_info "git-bootstrap: configurazione base completata (senza credential store)"
export __GIT_BOOTSTRAP_DONE=true
log_end_section
