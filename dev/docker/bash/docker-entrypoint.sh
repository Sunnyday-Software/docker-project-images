#!/usr/bin/dumb-init /usr/bin/bash

# https://github.com/Yelp/dumb-init
# Shell options: fail fast, catch pipe errors, and treat unset vars as errors
set -Eeuo pipefail
IFS=$'\n\t'

: "${DPM_DEBUG:=0}"

source "/opt/bash_libs/import_libs.sh"
log_enable_debug "${DPM_DEBUG}"

# ========================================
# AVVIO: Info immagine e contesto
# ========================================

# Legge la versione corrente dell'immagine
if [ -f /etc/image-info ]; then
    source /etc/image-info
else
    log_warn "⚠️  Warning: /etc/image-info not found"
    IMAGE_FULL_NAME="unknown"
fi

# ========================================
# HOME INIT (funziona anche senza privilegi)
# ========================================

HOME_VERSION_FILE="$HOME_DIR/.image-version"
NEEDS_UPDATE=false

if [ ! -f "$HOME_DIR/.bashrc" ] || [ ! -d "$HOME_DIR/.bashrc.d" ]; then
    log_debug "🏠 Home directory not initialized"
    NEEDS_UPDATE=true
elif [ ! -f "$HOME_VERSION_FILE" ]; then
    log_debug "⚠️  Home version file not found"
    NEEDS_UPDATE=true
else
    INSTALLED_VERSION=$(cat "$HOME_VERSION_FILE" 2>/dev/null || echo "")
    log_debug "📦 Installed home version: $INSTALLED_VERSION"

    if [ "$INSTALLED_VERSION" != "$IMAGE_FULL_NAME" ]; then
        log_debug "🔄 Home directory version mismatch - update needed"
        log_debug "   From: $INSTALLED_VERSION"
        log_debug "   To:   $IMAGE_FULL_NAME"
        NEEDS_UPDATE=true
    else
        log_debug "✅ Home directory is up to date"
    fi
fi

if [ "$NEEDS_UPDATE" = true ]; then
    log_debug "🔄 Updating home directory from template..."

    BACKUP_DIRS=(".ssh" ".config" ".cache")
    TEMP_BACKUP="/tmp/home-backup-$$"

    if [ -d "$HOME_DIR" ]; then
        mkdir -p "$TEMP_BACKUP"
        for dir in "${BACKUP_DIRS[@]}"; do
            if [ -d "$HOME_DIR/$dir" ]; then
                cp -a "$HOME_DIR/$dir" "$TEMP_BACKUP/" || true
            fi
        done
    fi

    log_debug "🧹 Cleaning old template files..."
    find "$HOME_DIR" -mindepth 1 -maxdepth 1 ! -name '.ssh' ! -name '.config' ! -name '.cache' -exec rm -rf {} + 2>/dev/null || true

    log_debug "📋 Copying new template..."
    cp -a /opt/home-template/. "$HOME_DIR/" 2>/dev/null || cp -r /opt/home-template/. "$HOME_DIR/" || true

    if [ -d "$TEMP_BACKUP" ]; then
        for dir in "${BACKUP_DIRS[@]}"; do
            if [ -d "$TEMP_BACKUP/$dir" ]; then
                cp -an "$TEMP_BACKUP/$dir/." "$HOME_DIR/$dir/" 2>/dev/null || true
            fi
        done
        rm -rf "$TEMP_BACKUP"
    fi

    echo "$IMAGE_FULL_NAME" > "$HOME_VERSION_FILE" 2>/dev/null || true
    log_debug "✅ Home directory updated to version: $IMAGE_FULL_NAME"
fi

# Override user_home (anche questo user-safe)
if [ -d "/opt/overrides/user_home/$USER" ]; then
  log_debug "🟪 Applying overrides from /opt/overrides/user_home/$USER to $HOME_DIR"
  cp -a "/opt/overrides/user_home/$USER/." "$HOME_DIR/" 2>/dev/null || cp -r "/opt/overrides/user_home/$USER/." "$HOME_DIR/" || true
fi

mkdir -p "$HOME_DIR/.ssh" "$HOME_DIR/.config" "$HOME_DIR/.local/bin" "$HOME_DIR/.cache" 2>/dev/null || true
chmod 700 "$HOME_DIR/.ssh" 2>/dev/null || true

. ~/.bashrc.d/load.sh

# ========================================
# ESECUZIONE FINALE (utente non-root)
# ========================================

log_debug_section "🚀 Avvio sessione utente: $USER"

ENTRYPOINT_SCRIPT='export HOME="'$HOME_DIR'"
cd "${DPM_PROJECT_ROOT:?DPM_PROJECT_ROOT non impostata}"

. ~/.bashrc.d/load.sh

if [ -n "${USE_TMUX+x}" ] && [[ "${USE_TMUX:-}" =~ ^(1|true|yes|on)$ ]]; then
  docker_entrypoint_tmux "$@"
else
  docker_entrypoint_common "$@"
fi'

exec bash -c "$ENTRYPOINT_SCRIPT" -- "$@"
