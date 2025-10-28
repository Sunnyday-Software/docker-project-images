#!/usr/bin/env bash
# Purpose: Non-interactive Git bootstrap for make image.
# Supports HTTPS (with token) and SSH (agent forwarding or env key), with CI tweaks.
# Defaults are safe and do not print secrets.

set -euo pipefail

log() { echo "[git-bootstrap] $*" >&2; }
warn() { echo "[git-bootstrap][WARN] $*" >&2; }
err() { echo "[git-bootstrap][ERROR] $*" >&2; }

# Avoid multiple runs
if [[ "${__GIT_BOOTSTRAP_DONE:-}" == "true" ]]; then
  return 0
fi
export __GIT_BOOTSTRAP_DONE=true

# Check GIT_CONFIG_GLOBAL environment variable and path
if [[ -n "${GIT_CONFIG_GLOBAL:-}" ]]; then
  if [[ ! -f "$GIT_CONFIG_GLOBAL" ]]; then
    mkdir -p "$GIT_CONFIG_GLOBAL"
    low "GIT_CONFIG_GLOBAL path '$GIT_CONFIG_GLOBAL' created";
  fi
fi


# Defaults
GIT_AUTH_MODE=${GIT_AUTH_MODE:-https}
GIT_CREDENTIALS_STORE_PATH=${GIT_CREDENTIALS_STORE_PATH:-/workdir/.git-credentials}
GIT_HTTP_HOST=${GIT_HTTP_HOST:-github.com}
GIT_SIGN_COMMITS=${GIT_SIGN_COMMITS:-false}
CI=${CI:-false}

# Sanitize mode
case "$GIT_AUTH_MODE" in
  https|ssh) ;;
  *) warn "GIT_AUTH_MODE '$GIT_AUTH_MODE' not recognized. Defaulting to 'https'."; GIT_AUTH_MODE=https ;;
esac
# Always disable GPG signing unless explicitly enabled
if [[ "$GIT_SIGN_COMMITS" != "true" ]]; then
  git config --global commit.gpgsign false || true
else
  # Enable GPG signing when requested
  if [[ -n "${GPG_PRIVATE_KEY:-}" ]]; then
    echo "$GPG_PRIVATE_KEY" | gpg --batch --quiet --import 2>/dev/null || true
    if [[ -n "${GPG_PASSPHRASE:-}" ]]; then
      git config --global gpg.program gpg
      git config --global user.signingkey "$(gpg --list-secret-keys --with-colons | awk -F: '/^sec:/ {print $5; exit}')"
    else
      git config --global user.signingkey "$(gpg --list-secret-keys --with-colons | awk -F: '/^sec:/ {print $5; exit}')"
    fi
    log "GPG signing enabled (key imported)."
  else
    warn "GIT_SIGN_COMMITS=true but GPG_PRIVATE_KEY not provided; leaving signing disabled."
    git config --global commit.gpgsign false || true
  fi
fi

setup_https() {
  local user token host
  user=${GIT_HTTP_USER:-}
  token=${GIT_HTTP_TOKEN:-}
  host=${GIT_HTTP_HOST}

  if [[ -z "$user" || -z "$token" ]]; then
    if [[ "${CI:-false}" == "true" ]]; then
      err "HTTPS mode requires GIT_HTTP_USER and GIT_HTTP_TOKEN to be set."; return 1
    else
      warn "HTTPS selected but GIT_HTTP_USER/GIT_HTTP_TOKEN not set; skipping Git credential setup (non-CI). Consider GIT_AUTH_MODE=ssh."
      return 0
    fi
  fi


  mkdir -p "$(dirname "$GIT_CREDENTIALS_STORE_PATH")"
  chmod 700 "$(dirname "$GIT_CREDENTIALS_STORE_PATH")" || true

  git config --global credential.helper "store --file=$GIT_CREDENTIALS_STORE_PATH"

  # Write credentials without echoing secrets
  local tmp_file
  tmp_file=$(mktemp)
  # Note: Do not log the content
  printf "https://%s:%s@%s\n" "$user" "$token" "$host" >"$tmp_file"
  chmod 600 "$tmp_file"
  mv "$tmp_file" "$GIT_CREDENTIALS_STORE_PATH"
  chmod 600 "$GIT_CREDENTIALS_STORE_PATH" || true

  log "Configured HTTPS credentials for host '$host' with credential store file set"
}

setup_ssh() {
  local known_hosts_file
  known_hosts_file=${GIT_SSH_KNOWN_HOSTS_FILE:-/root/.ssh/known_hosts}
  mkdir -p /root/.ssh
  chmod 700 /root/.ssh

  if [[ -n "${SSH_AUTH_SOCK:-}" && -S "${SSH_AUTH_SOCK}" ]]; then
    log "Using forwarded SSH agent via SSH_AUTH_SOCK."
  else
    if [[ -z "${GIT_SSH_PRIVATE_KEY:-}" ]]; then
      err "SSH mode without SSH_AUTH_SOCK requires GIT_SSH_PRIVATE_KEY."; return 1
    fi
    if [[ -z "${GIT_SSH_KNOWN_HOSTS:-}" ]]; then
      err "SSH mode without SSH_AUTH_SOCK requires GIT_SSH_KNOWN_HOSTS."; return 1
    fi
    eval "$(ssh-agent -s)" >/dev/null
    # Add key securely
    umask 077
    ssh-add - <<<"$GIT_SSH_PRIVATE_KEY" >/dev/null 2>&1 || { err "Failed to add SSH key"; return 1; }
    umask 022

    # Write known_hosts
    printf "%s\n" "$GIT_SSH_KNOWN_HOSTS" >"$known_hosts_file"
    chmod 600 "$known_hosts_file"
  fi

  # Force strict host checking
  git config --global core.sshCommand "ssh -o StrictHostKeyChecking=yes -o UserKnownHostsFile=$known_hosts_file"
  log "Configured SSH with strict host key checking and known_hosts at $known_hosts_file."
}

ci_adjustments() {
  # Set user name/email in CI if not set
  local name email
  name=${GIT_USER_NAME:-${GITHUB_ACTOR:-ci-bot}}
  email=${GIT_USER_EMAIL:-${GITHUB_ACTOR:-ci-bot}}@users.noreply.github.com
  git config --global user.name "$name" || true
  git config --global user.email "$email" || true

  # Ensure origin is HTTPS for GitHub repos if inside a git repo
  if git rev-parse --is-inside-work-tree >/dev/null 2>&1; then
    local remote_url
    remote_url=$(git remote get-url origin 2>/dev/null || true)
    if [[ -n "${remote_url}" ]]; then
      if [[ "${remote_url}" =~ ^git@github.com:(.+)\.git$ ]]; then
        local repo_path
        repo_path=${BASH_REMATCH[1]}
        local https_url="https://github.com/${repo_path}.git"
        git remote set-url origin "$https_url"
        log "Converted origin to HTTPS: $https_url"
      fi
    fi
  fi
}

# Execute mode-specific setup
case "$GIT_AUTH_MODE" in
  https)
    setup_https
    ;;
  ssh)
    setup_ssh
    ;;
 esac

# CI-specific steps
if [[ "$CI" == "true" ]]; then
  ci_adjustments
fi

# Final, avoid interactive prompts from git
export GIT_TERMINAL_PROMPT=0

# Summary without secrets
log "Mode: $GIT_AUTH_MODE | CI: $CI | Signing: $GIT_SIGN_COMMITS | Host: ${GIT_HTTP_HOST:-n/a}"
