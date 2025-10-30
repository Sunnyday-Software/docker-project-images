#!/usr/bin/env bash
# Scopo: configurare Git in modo non interattivo usando variabili d'ambiente.
# Requisiti: git presente nel PATH.
# Comportamento: se mancano GIT_HTTP_USER o GIT_HTTP_TOKEN, logga e termina senza errore.
# Robustezza: stampa configurazione iniziale e calcolata; verifica permessi prima di creare/scrivere; evita cross-device link.

# ========== UTILITIES ==========
log()  { echo "[git-bootstrap] $*" >&2; }
warn() { echo "[git-bootstrap][WARN] $*" >&2; }
err()  { echo "[git-bootstrap][ERROR] $*" >&2; }

print_fs_context() {
  log "PWD: $(pwd)"
  log "Listing here:"
  ls -la || true
  log "Listing /:"
  ls -la / || true
  for d in /workdir "${HOME:-/root}" "${XDG_CONFIG_HOME:-}" "$(dirname "${CRED_FILE:-/workdir/.git-credentials}")"; do
    [ -n "$d" ] || continue
    if [ -e "$d" ]; then
      log "Listing $d:"
      ls -la "$d" || true
      df -h "$d" || true
      stat "$d" || true
    else
      log "Path does not exist: $d"
    fi
  done
}

can_write_dir() {
  local d="$1"
  [ -d "$d" ] || return 1
  [ -w "$d" ] || return 1
  touch "$d/.writetest.$$" 2>/dev/null && rm -f "$d/.writetest.$$" 2>/dev/null
}

ensure_dir_writable() {
  # Crea la dir se mancante; verifica scrivibilità; se non scrivibile stampa contesto e ritorna 1
  local d="$1"
  if [ ! -d "$d" ]; then
    mkdir -p "$d" 2>/dev/null || {
      warn "Impossibile creare directory: $d"
      print_fs_context
      return 1
    }
  fi
  if ! can_write_dir "$d"; then
    warn "Directory non scrivibile: $d"
    print_fs_context
    return 1
  fi
  return 0
}

# Evita esecuzione multipla nel profilo interattivo
if [[ "${__GIT_BOOTSTRAP_DONE:-}" == "true" ]]; then
  log "Già configurato, skip."
  return 0
fi

# ========== CONFIGURAZIONE INIZIALE (INPUT) ==========
# GIT_HTTP_USER: obbligatoria per HTTPS, username o 'x-access-token' per GitHub (se manca: uscita soft)
log "Variabile: GIT_HTTP_USER - Necessaria per auth HTTPS; Obbligatoria: sì; Fonte: env; Default: n/d"
log "Valore: ${GIT_HTTP_USER:-<unset>}"

# GIT_HTTP_TOKEN: obbligatoria per HTTPS, PAT GitHub (se manca: uscita soft)
log "Variabile: GIT_HTTP_TOKEN - Necessaria per auth HTTPS; Obbligatoria: sì; Fonte: env; Default: n/d"
log "Valore: ${GIT_HTTP_TOKEN:+***masked***}${GIT_HTTP_TOKEN:-<unset>:+}"

# GIT_HTTP_HOST: host Git (default github.com)
log "Variabile: GIT_HTTP_HOST - Host Git; Obbligatoria: no; Fonte: env; Default: github.com"
log "Valore: ${GIT_HTTP_HOST:-<default>}"

# CRED_FILE: path file credenziali git-credential-store
log "Variabile: CRED_FILE - File credenziali; Obbligatoria: no; Fonte: env; Default: /workdir/.git-credentials"
log "Valore: ${CRED_FILE:-/workdir/.git-credentials}"

# XDG_CONFIG_HOME: base config (se assente calcoliamo fallback su /workdir)
log "Variabile: XDG_CONFIG_HOME - Base config; Obbligatoria: no; Fonte: env; Default: <calcolato>"

# HOME: usato da git se non sovrascritto (potremmo ricalcolarlo)
log "Variabile: HOME - Home utente; Obbligatoria: no; Fonte: ambiente container"
log "Valore: ${HOME:-<unset>}"

# CI: indicatore ambiente CI
log "Variabile: CI - Contesto CI; Obbligatoria: no; Fonte: env; Default: false"
log "Valore: ${CI:-false}"

# Se mancano le variabili obbligatorie, uscita soft
if [ -z "${GIT_HTTP_USER:-}" ]; then
  warn "GIT_HTTP_USER non impostata: esco senza configurare git."
  export __GIT_BOOTSTRAP_DONE=true
  return 0
fi
if [ -z "${GIT_HTTP_TOKEN:-}" ]; then
  warn "GIT_HTTP_TOKEN non impostata: esco senza configurare git."
  export __GIT_BOOTSTRAP_DONE=true
  return 0
fi

# ========== CALCOLI DERIVATI ==========
GITHUB_HOST="${GIT_HTTP_HOST:-github.com}"
CRED_FILE="${CRED_FILE:-/workdir/.git-credentials}"

# Per evitare 'Invalid cross-device link' usiamo lo stesso FS di /workdir
RUNTIME_BASE="/workdir/.runtime/git"
CONFIG_HOME="${XDG_CONFIG_HOME:-$RUNTIME_BASE}"
SAFE_HOME="${HOME:-$RUNTIME_BASE/home}"
TMPDIR_CALC="${CONFIG_HOME}/.tmp"
GIT_GLOBAL_CONFIG="${CONFIG_HOME}/git/config"

# Token sanitizzato
token="${GIT_HTTP_TOKEN%$'\n'}"; token="${token%$'\r'}"

# Stampa variabili calcolate
log "Calcolata: GITHUB_HOST - Host usato per remoti HTTPS; Default: github.com"
log "Valore: ${GITHUB_HOST}"

log "Calcolata: RUNTIME_BASE - Radice runtime su /workdir per stesso filesystem; Default: /workdir/.runtime/git"
log "Valore: ${RUNTIME_BASE}"

log "Calcolata: CONFIG_HOME - Base config effettiva; Default: \$RUNTIME_BASE"
log "Valore: ${CONFIG_HOME}"

log "Calcolata: SAFE_HOME - HOME effettiva per operazioni git; Default: \$RUNTIME_BASE/home"
log "Valore: ${SAFE_HOME}"

log "Calcolata: TMPDIR - Temporary directory per operazioni atomiche git; Default: \$CONFIG_HOME/.tmp"
log "Valore: ${TMPDIR_CALC}"

log "Calcolata: GIT_GLOBAL_CONFIG - Percorso config globale; Default: \$CONFIG_HOME/git/config"
log "Valore: ${GIT_GLOBAL_CONFIG}"

log "Calcolata: CRED_FILE - File credenziali git; Default: /workdir/.git-credentials"
log "Valore: ${CRED_FILE}"

# ========== PRE-CHECK PERMESSI E FS ==========
# Verifica /workdir
if ! ensure_dir_writable "/workdir"; then
  warn "Impossibile garantire scrittura su /workdir; skip configurazione git."
  export __GIT_BOOTSTRAP_DONE=true
  return 0
fi

# Verifica CONFIG_HOME, SAFE_HOME, TMPDIR e dir credenziali
ensure_dir_writable "$CONFIG_HOME"     || { warn "CONFIG_HOME non scrivibile"; export __GIT_BOOTSTRAP_DONE=true; return 0; }
ensure_dir_writable "$SAFE_HOME"       || { warn "SAFE_HOME non scrivibile"; export __GIT_BOOTSTRAP_DONE=true; return 0; }
ensure_dir_writable "$TMPDIR_CALC"     || { warn "TMPDIR non scrivibile"; export __GIT_BOOTSTRAP_DONE=true; return 0; }
ensure_dir_writable "$(dirname "$GIT_GLOBAL_CONFIG")" || { warn "Dir config git non scrivibile"; export __GIT_BOOTSTRAP_DONE=true; return 0; }
ensure_dir_writable "$(dirname "$CRED_FILE")" || { warn "Dir credenziali non scrivibile"; export __GIT_BOOTSTRAP_DONE=true; return 0; }

# ========== EXPORT AMBIENTE PER GIT ==========
export HOME="${SAFE_HOME}"
export XDG_CONFIG_HOME="${CONFIG_HOME}"
export TMPDIR="${TMPDIR_CALC}"
export GIT_CONFIG_GLOBAL="${GIT_GLOBAL_CONFIG}"
export GIT_TERMINAL_PROMPT=0

# ========== CONFIGURAZIONE GIT ==========
# Inizializza il file di config se non esiste
if [ ! -f "$GIT_CONFIG_GLOBAL" ]; then
  : > "$GIT_CONFIG_GLOBAL" 2>/dev/null || {
    warn "Impossibile creare $GIT_CONFIG_GLOBAL"
    print_fs_context
    export __GIT_BOOTSTRAP_DONE=true
    return 0
  }
fi

# Imposta config globale (fallimento soft con log)
git config --global --unset-all credential.helper 2>/dev/null || true
git config --global credential.helper "store --file=${CRED_FILE}" 2>/dev/null || warn "credential.helper non impostato"
git config --global credential.useHttpPath false 2>/dev/null || true
git config --global url."https://${GITHUB_HOST}/".insteadOf "git@${GITHUB_HOST}:" 2>/dev/null || warn "url.insteadOf non impostato"
git config --global user.name  "${GIT_USER_NAME:-${GITHUB_ACTOR:-ci-bot}}" 2>/dev/null || warn "user.name non impostato"
git config --global user.email "${GIT_USER_EMAIL:-${GITHUB_ACTOR:-ci-bot}}@users.noreply.github.com" 2>/dev/null || warn "user.email non impostato"
git config --global commit.gpgsign false 2>/dev/null || true
git config --global --add safe.directory /workdir 2>/dev/null || true

# ========== CREDENZIALI ==========
umask 077
# Verifica scrittura credenziali
if ! can_write_dir "$(dirname "$CRED_FILE")"; then
  warn "Directory credenziali non scrivibile: $(dirname "$CRED_FILE")"
  print_fs_context
  export __GIT_BOOTSTRAP_DONE=true
  return 0
fi

printf "https://%s:%s@%s\n" "${GIT_HTTP_USER}" "${token}" "${GITHUB_HOST}" > "${CRED_FILE}" 2>/dev/null || {
  warn "Impossibile scrivere il file credenziali: ${CRED_FILE}"
  print_fs_context
  export __GIT_BOOTSTRAP_DONE=true
  return 0
}
chmod 600 "${CRED_FILE}" 2>/dev/null || true

# ========== REMOTE ORIGIN (OPZIONALE) ==========
if git -C /workdir rev-parse --is-inside-work-tree >/dev/null 2>&1; then
  url="$(git -C /workdir remote get-url origin 2>/dev/null || true)"
  if [ -n "${url}" ] && printf '%s' "${url}" | grep -q '^git@' ; then
    https_url="$(printf '%s' "${url}" | sed "s#^git@${GITHUB_HOST}:#https://${GITHUB_HOST}/#")"
    git -C /workdir remote set-url origin "${https_url}" 2>/dev/null || warn "Impossibile aggiornare origin a HTTPS"
    log "Origin convertito a HTTPS: ${https_url}"
  fi
fi

# ========== DEBUG ==========
log "=== DEBUG CONFIGURAZIONE (safe) ==="
log "Descrizione: HOME effettiva usata per git (stesso FS di /workdir per evitare cross-device link)"
log "HOME=${HOME}"
log "Descrizione: Base config (XDG) usata per git"
log "XDG_CONFIG_HOME=${XDG_CONFIG_HOME}"
log "Descrizione: File di config globale git"
log "GIT_CONFIG_GLOBAL=${GIT_CONFIG_GLOBAL}"
log "Descrizione: File credenziali git-credential-store"
log "CRED_FILE=${CRED_FILE}"
git config --list --show-origin 2>/dev/null | grep -E 'credential|user\.|url\.|safe\.directory' || true
log "==============================="

export __GIT_BOOTSTRAP_DONE=true
log "✅ Configurazione Git completata (soft-fail abilitato dove necessario)"