#!/usr/bin/env bash

# https://github.com/Yelp/dumb-init

echo "Running docker-entrypoint.sh"

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

# Funzione per loggare ed eseguire comandi
log_and_execute() {
    echo "🔍 [$(date '+%Y-%m-%d %H:%M:%S')] Executing: $*" >&2
    "$@"
    local exit_code=$?
    if [ $exit_code -eq 0 ]; then
        echo "✅ [$(date '+%Y-%m-%d %H:%M:%S')] Command succeeded" >&2
    else
        echo "❌ [$(date '+%Y-%m-%d %H:%M:%S')] Command failed with exit code: $exit_code" >&2
    fi
    return $exit_code
}


# Set up the trap to catch errors
trap 'error_handler ${LINENO} "$BASH_COMMAND" $?' ERR

set -e

# Inizializza la home se è vuota o incompleta (primo avvio o volume pulito)
if [ ! -f "$HOME/.bashrc" ] || [ ! -d "$HOME/.bashrc.d" ]; then
    echo "🏠 Initializing home directory from template..."
    
    # Copia il template preservando permessi e timestamp
    # -a: archive mode (preserva tutto)
    # -n: no-clobber (non sovrascrive file esistenti)
    cp -an /opt/home-template/. "$HOME/"
    
    echo "✅ Home directory initialized from /opt/home-template"
    
    # Debug: mostra cosa è stato copiato
    if [ "${DEBUG:-false}" = "true" ]; then
        echo "📂 Home directory contents:"
        ls -la "$HOME"
        echo "📂 .bashrc.d contents:"
        ls -la "$HOME/.bashrc.d"
    fi
else
    echo "ℹ️  Home directory already initialized"
fi

# Crea directory standard se non esistono
mkdir -p "$HOME/.ssh" "$HOME/.config" "$HOME/.local/bin" "$HOME/.cache"
chmod 700 "$HOME/.ssh" || true

# Prevent core dumps
ulimit -c 0

. ~/.bashrc.d/docker_entrypoint_common.sh

docker_entrypoint_common "$@"

