#!/usr/bin/env bash
set -e

GPG_KEY="${GPG_KEY:-default@example.com}"
CRED_FILE="${CRED_FILE:-.runtime/git-credentials.gpg}"

case "$1" in
    get)
        if [ -f "$CRED_FILE" ]; then
            gpg --decrypt "$CRED_FILE"
        fi
        ;;
    store)
        # Riceve dalle stdin le credenziali formattate da git
        cred=$(cat)
        echo "$cred" | gpg --encrypt --armor --recipient "$GPG_KEY" > "$CRED_FILE"
        ;;
    erase)
        rm -f "$CRED_FILE"
        ;;
esac
