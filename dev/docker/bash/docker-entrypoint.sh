#!/usr/bin/dumb-init /usr/bin/bash

# https://github.com/Yelp/dumb-init


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
echo "📂 Current working directory: $(pwd)"

# ========================================
# OPERAZIONI PRIVILEGIATE (come root)
# ========================================

# Legge la versione corrente dell'immagine
if [ -f /etc/image-info ]; then
    source /etc/image-info
    echo "📦 Current image version: $IMAGE_FULL_NAME"
else
    echo "⚠️  Warning: /etc/image-info not found"
    IMAGE_FULL_NAME="unknown"
fi

# File marker della versione nella home dell'utente
HOME_VERSION_FILE="$HOME_DIR/.image-version"

# Verifica se la home deve essere inizializzata o aggiornata
NEEDS_UPDATE=false

if [ ! -f "$HOME_DIR/.bashrc" ] || [ ! -d "$HOME_DIR/.bashrc.d" ]; then
    echo "🏠 Home directory not initialized"
    NEEDS_UPDATE=true
elif [ ! -f "$HOME_VERSION_FILE" ]; then
    echo "⚠️  Home version file not found"
    NEEDS_UPDATE=true
else
    INSTALLED_VERSION=$(cat "$HOME_VERSION_FILE")
    echo "📦 Installed home version: $INSTALLED_VERSION"

    if [ "$INSTALLED_VERSION" != "$IMAGE_FULL_NAME" ]; then
        echo "🔄 Home directory version mismatch - update needed"
        echo "   From: $INSTALLED_VERSION"
        echo "   To:   $IMAGE_FULL_NAME"
        NEEDS_UPDATE=true
    else
        echo "✅ Home directory is up to date"
    fi
fi

# Aggiorna la home se necessario
if [ "$NEEDS_UPDATE" = true ]; then
    echo "🔄 Updating home directory from template..."

    # Backup dei file utente importanti se esistono
    BACKUP_DIRS=(".ssh" ".config" ".cache")
    TEMP_BACKUP="/tmp/home-backup-$$"

    if [ -d "$HOME_DIR" ]; then
        mkdir -p "$TEMP_BACKUP"
        for dir in "${BACKUP_DIRS[@]}"; do
            if [ -d "$HOME_DIR/$dir" ]; then
                echo "💾 Backing up $dir"
                cp -a "$HOME_DIR/$dir" "$TEMP_BACKUP/" || true
            fi
        done
    fi

    # Rimuove i file template vecchi (ma preserva i backup)
    echo "🧹 Cleaning old template files..."
    find "$HOME_DIR" -mindepth 1 -maxdepth 1 ! -name '.ssh' ! -name '.config' ! -name '.cache' -exec rm -rf {} + 2>/dev/null || true

    # Copia il nuovo template
    echo "📋 Copying new template..."
    cp -a /opt/home-template/. "$HOME_DIR/"

    # Ripristina i backup
    if [ -d "$TEMP_BACKUP" ]; then
        for dir in "${BACKUP_DIRS[@]}"; do
            if [ -d "$TEMP_BACKUP/$dir" ]; then
                echo "♻️  Restoring $dir"
                cp -an "$TEMP_BACKUP/$dir/." "$HOME_DIR/$dir/" 2>/dev/null || true
            fi
        done
        rm -rf "$TEMP_BACKUP"
    fi

    # Salva la versione corrente
    echo "$IMAGE_FULL_NAME" > "$HOME_VERSION_FILE"

    echo "✅ Home directory updated to version: $IMAGE_FULL_NAME"

    # Debug: mostra cosa è stato copiato
    if [ "${DEBUG:-false}" = "true" ]; then
        echo "📂 Home directory contents:"
        ls -la "$HOME_DIR"
        echo "📂 .bashrc.d contents:"
        ls -la "$HOME_DIR/.bashrc.d"
    fi
fi

# Crea directory standard se non esistono
mkdir -p "$HOME_DIR/.ssh" "$HOME_DIR/.config" "$HOME_DIR/.local/bin" "$HOME_DIR/.cache"
chmod 700 "$HOME_DIR/.ssh" || true

# Assicura che tutti i file nella home abbiano il proprietario corretto
chown -R $USER:$GROUP "$HOME_DIR"

# Prevent core dumps
ulimit -c 0

echo "✅ Privileged operations completed"

# ========================================
# CAMBIO UTENTE (preservando l'ambiente)
# ========================================

echo "👤 Switching to user: $USER"

# gosu preserva le variabili d'ambiente e esegue come utente non privilegiato
# Passa il controllo allo script non privilegiato
exec gosu $USER bash -c '
    export HOME="'"$HOME_DIR"'"
    # Cambia esplicitamente alla directory di lavoro
    cd /workdir

    echo "👤 Now running as: $(whoami) (UID=$(id -u), GID=$(id -g))"
    echo "🏠 HOME is now: $HOME"
    echo "📂 Working directory is now: $(pwd)"

    # Esegue il comando finale
    . ~/.bashrc.d/load.sh

    if [ -n "${USE_TMUX:-}" ]; then
      docker_entrypoint_tmux "$@"
    else
      docker_entrypoint_common "$@"
    fi
' -- "$@"



