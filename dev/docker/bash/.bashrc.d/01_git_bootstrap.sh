#!/usr/bin/env bash
# Configure Git non-interactively in CI from env vars
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

set -e

# Evita esecuzione multipla
if [[ "${__GIT_BOOTSTRAP_DONE:-}" == "true" ]]; then
    log "Already configured, skipping"
    return 0
fi

# --- Inputs ---
# --- Verifica variabili obbligatorie (senza bloccare) ---
if [ -z "${GIT_HTTP_USER:-}" ]; then
    warn "GIT_HTTP_USER not set - skipping git configuration"
    warn "Set GIT_HTTP_USER to your GitHub login to enable git config"
    export __GIT_BOOTSTRAP_DONE=true
    return 0
fi

if [ -z "${GIT_HTTP_TOKEN:-}" ]; then
    warn "GIT_HTTP_TOKEN not set - skipping git configuration"
    warn "Set GIT_HTTP_TOKEN to a valid GitHub PAT to enable git config"
    export __GIT_BOOTSTRAP_DONE=true
    return 0
fi

GITHUB_HOST="${GIT_HTTP_HOST:-github.com}"
CRED_FILE="${CRED_FILE:-/workdir/.git-credentials}"   # dove salvare le credenziali

# Usa una directory nel filesystem di /workdir per evitare cross-device link
CONFIG_HOME="${XDG_CONFIG_HOME:-/workdir/.runtime/git}"       # global config dir

# --- Sanitizza token (no CR/LF) ---
token="${GIT_HTTP_TOKEN%$'\n'}"; token="${token%$'\r'}"

# --- Global git config in posto scrivibile ---
mkdir -p "${CONFIG_HOME}" /workdir || true

# Workaround per "Invalid cross-device link": imposta HOME e XDG_CONFIG_HOME nello stesso filesystem
export HOME="${HOME:-/workdir/.runtime/git/home}"
export XDG_CONFIG_HOME="${CONFIG_HOME}"
export TMPDIR="${CONFIG_HOME}/.tmp"
mkdir -p "$HOME" "$XDG_CONFIG_HOME/git" "$TMPDIR" || true

# Configura Git per usare la nuova HOME
export GIT_CONFIG_GLOBAL="${XDG_CONFIG_HOME}/git/config"

# Inizializza il file di config se non esiste
touch "$GIT_CONFIG_GLOBAL" || true

git config --global --unset-all credential.helper >/dev/null 2>&1 || true
git config --global credential.helper "store --file=${CRED_FILE}"
git config --global credential.useHttpPath false
git config --global url."https://${GITHUB_HOST}/".insteadOf "git@${GITHUB_HOST}:"
git config --global user.name  "${GIT_USER_NAME:-${GITHUB_ACTOR:-ci-bot}}"
git config --global user.email "${GIT_USER_EMAIL:-${GITHUB_ACTOR:-ci-bot}}@users.noreply.github.com"
git config --global commit.gpgsign false
export GIT_TERMINAL_PROMPT=0

# Aggiungi /workdir come safe directory
git config --global --add safe.directory /workdir || true

# --- Scrivi credenziali (host-level) ---
umask 077
printf "https://%s:%s@%s\n" "${GIT_HTTP_USER}" "${token}" "${GITHUB_HOST}" > "${CRED_FILE}"
chmod 600 "${CRED_FILE}"

# --- Se il repo è già checkoutato, converti origin a HTTPS se serve ---
if git -C /workdir rev-parse --is-inside-work-tree >/dev/null 2>&1; then
  url="$(git -C /workdir remote get-url origin 2>/dev/null || true)"
  if [ -n "${url}" ] && printf '%s' "${url}" | grep -q '^git@' ; then
    https_url="$(printf '%s' "${url}" | sed "s#^git@${GITHUB_HOST}:#https://${GITHUB_HOST}/#")"
    git -C /workdir remote set-url origin "${https_url}"
  fi
fi

# --- Debug "safe" ---
echo "=== GIT DEBUG (safe) ==="
echo "HOME=$HOME"
echo "XDG_CONFIG_HOME=$XDG_CONFIG_HOME"
echo "GIT_CONFIG_GLOBAL=$GIT_CONFIG_GLOBAL"
git config --list --show-origin | grep -E 'credential|user\.|url\.|safe\.directory' || true
printf "protocol=https\\nhost=%s\\n" "${GITHUB_HOST}" | git credential fill 2>/dev/null | sed -E 's/(password=).*/\1***hidden***/' || echo "credential fill failed"
echo "========================"

