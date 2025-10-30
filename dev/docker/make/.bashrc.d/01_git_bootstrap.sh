#!/usr/bin/env bash
# Configure Git non-interactively in CI from env vars
set -euo pipefail


# --- Inputs ---
: "${GIT_HTTP_USER:?Set GIT_HTTP_USER to your GitHub login (not email)}"
: "${GIT_HTTP_TOKEN:?Set GIT_HTTP_TOKEN to a valid GitHub PAT}"
GITHUB_HOST="${GIT_HTTP_HOST:-github.com}"
CRED_FILE="${CRED_FILE:-/workdir/.git-credentials}"   # dove salvare le credenziali
CONFIG_HOME="${XDG_CONFIG_HOME:-$HOME/.config}"       # global config dir

# --- Sanitizza token (no CR/LF) ---
token="${GIT_HTTP_TOKEN%$'\n'}"; token="${token%$'\r'}"

# --- Global git config in posto scrivibile ---
mkdir -p "${CONFIG_HOME}/git" /workdir || true

# Workaround per "Invalid cross-device link": imposta TMPDIR nello stesso filesystem di HOME
export TMPDIR="${CONFIG_HOME}/.cache/tmp"
mkdir -p "$TMPDIR" || true

git config --global --unset-all credential.helper >/dev/null 2>&1 || true
git config --global credential.helper "store --file=${CRED_FILE}"
git config --global credential.useHttpPath false
git config --global url."https://${GITHUB_HOST}/".insteadOf "git@${GITHUB_HOST}:"
git config --global user.name  "${GIT_USER_NAME:-${GITHUB_ACTOR:-ci-bot}}"
git config --global user.email "${GIT_USER_EMAIL:-${GITHUB_ACTOR:-ci-bot}}@users.noreply.github.com"
git config --global commit.gpgsign false
export GIT_TERMINAL_PROMPT=0

# --- Scrivi credenziali (host-level) ---
umask 077
printf "https://%s:%s@%s\n" "${GIT_HTTP_USER}" "${token}" "${GITHUB_HOST}" > "${CRED_FILE}"
chmod 600 "${CRED_FILE}"

# --- Se il repo è già checkoutato, converti origin a HTTPS se serve ---
if git rev-parse --is-inside-work-tree >/dev/null 2>&1; then
  url="$(git remote get-url origin || true)"
  if [ -n "${url}" ] && printf '%s' "${url}" | grep -q '^git@' ; then
    https_url="$(printf '%s' "${url}" | sed "s#^git@${GITHUB_HOST}:#https://${GITHUB_HOST}/#")"
    git remote set-url origin "${https_url}"
  fi
fi

# --- Debug “safe” ---
echo "=== GIT DEBUG (safe) ==="
git config --list --show-origin | grep -E 'credential|user\.|url\.' || true
printf "protocol=https\\nhost=%s\\n" "${GITHUB_HOST}" | git credential fill | sed -E 's/(password=).*/\\1***hidden***/'
echo "========================"
