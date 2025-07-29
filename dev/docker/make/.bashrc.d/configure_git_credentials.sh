#!/usr/bin/env bash
set -e

CHECK_FILE="${HOME}/.runtime/git-credential-test.gpg"
GPG_KEY="${GPG_KEY:-default@example.com}"

# Function: Initial setup
setup_passphrase() {
  echo "🔐 First run: set GPG passphrase for git credentials."
  while true; do
    read -s -p "Choose a GPG passphrase: " pass1
    echo
    read -s -p "Repeat the passphrase: " pass2
    echo
    if [[ "$pass1" != "$pass2" ]]; then
      echo "❌ Passphrases do not match, please try again."
      continue
    fi
    # Try generating encrypted test file
    echo "test-gpg-credentials" | \
      gpg --batch --yes --symmetric --passphrase "$pass1" --output "$CHECK_FILE"
    # Immediately try reading/decrypting to validate
    if echo "$pass1" | \
        gpg --batch --yes --passphrase-fd 0 --decrypt "$CHECK_FILE" &>/dev/null; then
      echo "✅ Passphrase correctly set and verified."
      break
    else
      echo "❌ Verification failed, please try again."
      rm -f "$CHECK_FILE"
    fi
  done
}

# Function: verify passphrase on subsequent runs
verify_passphrase() {
  local attempt=1
  while (( attempt <= 3 )); do
    read -s -p "Enter GPG passphrase to unlock git credentials: " pass
    echo
    if echo "$pass" | gpg --batch --yes --passphrase-fd 0 --decrypt "$CHECK_FILE" &>/dev/null; then
      echo "✅ Correct passphrase!"
      break
    else
      echo "❌ Incorrect passphrase!"
    fi
    ((attempt++))
  done
  if (( attempt > 3 )); then
    echo "❌ Too many failed attempts. Exiting."
    exit 1
  fi
}


if [[ "${CI:-false}" == "true" ]]; then
  git config --global --unset credential.helper || true
else
  mkdir -p "$(dirname "$CHECK_FILE")"

  if [ ! -f "$CHECK_FILE" ]; then
    setup_passphrase
  else
    verify_passphrase
  fi

  export GPG_TTY=$(tty)
  # Set custom GPG helper
  git config --global credential.helper \
    "!bash /usr/local/bin/git-credential-gpg.sh"
fi
