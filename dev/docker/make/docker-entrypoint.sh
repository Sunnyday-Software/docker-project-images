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

echo "🔐 Running as root: $(whoami)"
echo "🏠 HOME_DIR is set to: $HOME_DIR"
echo "🏠 Current HOME is: $HOME"

# ========================================
# OPERAZIONI PRIVILEGIATE (come root)
# ========================================
# Inizializza la home se è vuota o incompleta (primo avvio o volume pulito)
if [ ! -f "$HOME_DIR/.bashrc" ] || [ ! -d "$HOME_DIR/.bashrc.d" ]; then
    echo "🏠 Initializing home directory from template..."
    
    # Copia il template preservando permessi e timestamp
    # -a: archive mode (preserva tutto)
    # -n: no-clobber (non sovrascrive file esistenti)
    cp -an /opt/home-template/. "$HOME_DIR/"
    
    echo "✅ Home directory initialized from /opt/home-template"
    
    # Debug: mostra cosa è stato copiato
    if [ "${DEBUG:-false}" = "true" ]; then
        echo "📂 Home directory contents:"
        ls -la "$HOME_DIR"
        echo "📂 .bashrc.d contents:"
        ls -la "$HOME_DIR/.bashrc.d"
    fi
else
    echo "ℹ️  Home directory already initialized"
fi

# Crea directory standard se non esistono
mkdir -p "$HOME_DIR/.ssh" "$HOME_DIR/.config" "$HOME_DIR/.local/bin" "$HOME_DIR/.cache"
chmod 700 "$HOME_DIR/.ssh" || true

# Assicura che tutti i file nella home abbiano il proprietario corretto
chown -R $USER:$GROUP "$HOME_DIR"

# Gestione socket Docker
if [ -S /var/run/docker.sock ]; then
    DOCKER_SOCK_GID=$(stat -c '%g' /var/run/docker.sock)
    echo "🐳 Docker socket detected with GID: $DOCKER_SOCK_GID"

    # Crea un gruppo con lo stesso GID se non esiste
    if ! getent group $DOCKER_SOCK_GID > /dev/null; then
        groupadd -g $DOCKER_SOCK_GID dockerhost
        echo "✅ Created group dockerhost with GID $DOCKER_SOCK_GID"
    fi

    # Aggiungi l'utente al gruppo
    usermod -aG $DOCKER_SOCK_GID $USER
    echo "✅ User $USER added to docker socket group"
fi

# Prevent core dumps
ulimit -c 0

# gosu preserva le variabili d'ambiente e esegue come utente non privilegiato
# Passa il controllo allo script non privilegiato
exec gosu $USER bash -c '
    export HOME="'"$HOME_DIR"'"
    cd "$HOME" || cd /workdir

    echo "👤 Now running as: $(whoami) (UID=$(id -u), GID=$(id -g))"
    echo "🏠 HOME is now: $HOME"

    # Source la configurazione bash
    source ~/.bashrc.d/docker_entrypoint_common.sh

    # Esegue il comando finale
    docker_entrypoint_common "$@"
' -- "$@"

