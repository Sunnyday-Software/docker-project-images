#!/usr/bin/env bash
# Deprecated interactive credential configuration. Replaced by 01_git_bootstrap.sh.
# This script is kept for backward compatibility and does nothing.
# It ensures we never prompt interactively.
set -euo pipefail

echo "Running configure_git_credentials.sh"

# Explicitly disable any previously set custom credential helper that may prompt
if git config --global --get credential.helper >/dev/null 2>&1; then
  helper=$(git config --global --get credential.helper || true)
  case "$helper" in
    *git-credential-gpg.sh*) git config --global --unset credential.helper || true ;;
  esac
fi

# No-op: 01_git_bootstrap.sh handles HTTPS/SSH/CI flows non-interactively.
exit 0
