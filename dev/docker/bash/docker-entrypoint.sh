#!/usr/bin/dumb-init /usr/bin/bash

# https://github.com/Yelp/dumb-init

: "${DPM_DEBUG:=0}"

source "/opt/bash_libs/import_libs.sh"
log_enable_debug "${DPM_DEBUG}"


# Funzione per gestire i gruppi extra
setup_extra_groups() {
  local extra_gids="${DPM_USER_ADD_GID_S_LIST:-}"

  if [ -z "$extra_gids" ]; then
    log_debug "ℹ️  Nessun gruppo extra da configurare (DPM_USER_ADD_GID_S_LIST non impostato)"
    return 0
  fi

  log_debug "🔧 Configurazione gruppi extra per $USER..."

  # Split per virgola o spazio
  IFS=',' read -ra GIDS <<< "$extra_gids"

  for gid in "${GIDS[@]}"; do
    # Rimuovi spazi
    gid=$(echo "$gid" | xargs)

    # Verifica che sia un numero
    if ! [[ "$gid" =~ ^[0-9]+$ ]]; then
      log_debug "⚠️  Warning: GID '$gid' non valido, ignorato"
      continue
    fi

    # Verifica se il GID è già in uso
    existing_group=$(getent group "$gid" | cut -d: -f1 || echo "")

    if [ -n "$existing_group" ]; then
      log_debug "  ➤ Gruppo esistente trovato: $existing_group (GID: $gid)"
      group_name="$existing_group"
    else
      # Crea un gruppo fittizio con quel GID
      group_name="hostgid_${gid}"
      log_debug "  ➤ Creazione gruppo fittizio: $group_name (GID: $gid)"

      if groupadd -g "$gid" "$group_name" 2>/dev/null; then
        log_debug "    ✅ Gruppo $group_name creato"
      else
        log_debug "    ⚠️  Impossibile creare gruppo con GID $gid, ignorato"
        continue
      fi
    fi

    # Aggiungi l'utente al gruppo
    if usermod -aG "$group_name" "$USER" 2>/dev/null; then
      log_debug "    ✅ Utente $USER aggiunto al gruppo $group_name (GID: $gid)"
    else
      log_debug "    ⚠️  Impossibile aggiungere $USER al gruppo $group_name"
    fi
  done

  log_debug "✅ Configurazione gruppi extra completata"
  log_debug "📋 Gruppi dell'utente $USER: $(id -Gn $USER)"
}




# ========================================
# OPERAZIONI PRIVILEGIATE (come root)
# ========================================

# Legge la versione corrente dell'immagine
if [ -f /etc/image-info ]; then
    source /etc/image-info
else
    log_warn "⚠️  Warning: /etc/image-info not found"
    IMAGE_FULL_NAME="unknown"
fi

log_debug_section "${IMAGE_FULL_NAME:-unknown image}"
log_debug "🔐 Running as user: $(whoami) (UID=$(id -u), GID=$(id -g))"
log_debug "🏠 HOME_DIR (user home folder) is set to: $HOME_DIR"
log_debug "🏠 Current HOME is: $HOME"
log_debug "📂 Current working directory: $(pwd)"

# Runtime Checks & Warnings
if [ ! -w . ]; then
    log_warn "⚠️  Warning: Current working directory is not writable by current user!"
fi

if [ -n "${DOCKER_HOST:-}" ]; then
    log_debug "🐋 DOCKER_HOST detected: $DOCKER_HOST"
fi

if [[ -S /var/run/docker.sock ]]; then
    log_debug "🐋 Docker socket found at /var/run/docker.sock"
    if [ ! -w /var/run/docker.sock ]; then
        log_warn "⚠️  Warning: Docker socket exists but is not writable by current user."
    fi
else
    log_debug "ℹ️  No Docker socket found at /var/run/docker.sock"
fi

# Check for rootless indicators
if [ "$(id -u)" -eq 0 ]; then
    log_debug "👑 Process is running as root (could be native root or rootless-mapped root)"
else
    log_debug "👤 Process is running as non-root user $(id -u)"
fi

# File marker della versione nella home dell'utente
HOME_VERSION_FILE="$HOME_DIR/.image-version"

# Verifica se la home deve essere inizializzata o aggiornata
NEEDS_UPDATE=false

if [ ! -f "$HOME_DIR/.bashrc" ] || [ ! -d "$HOME_DIR/.bashrc.d" ]; then
    log_debug "🏠 Home directory not initialized"
    NEEDS_UPDATE=true
elif [ ! -f "$HOME_VERSION_FILE" ]; then
    log_debug "⚠️  Home version file not found"
    NEEDS_UPDATE=true
else
    INSTALLED_VERSION=$(cat "$HOME_VERSION_FILE")
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

# Aggiorna la home se necessario
if [ "$NEEDS_UPDATE" = true ]; then
    log_debug "🔄 Updating home directory from template..."

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
    log_debug "🧹 Cleaning old template files..."
    find "$HOME_DIR" -mindepth 1 -maxdepth 1 ! -name '.ssh' ! -name '.config' ! -name '.cache' -exec rm -rf {} + 2>/dev/null || true

    # Copia il nuovo template
    log_debug "📋 Copying new template..."
    cp -a /opt/home-template/. "$HOME_DIR/"

    # Ripristina i backup
    if [ -d "$TEMP_BACKUP" ]; then
        for dir in "${BACKUP_DIRS[@]}"; do
            if [ -d "$TEMP_BACKUP/$dir" ]; then
                log_debug "♻️  Restoring $dir"
                cp -an "$TEMP_BACKUP/$dir/." "$HOME_DIR/$dir/" 2>/dev/null || true
            fi
        done
        rm -rf "$TEMP_BACKUP"
    fi

    # Salva la versione corrente
    echo "$IMAGE_FULL_NAME" > "$HOME_VERSION_FILE"

    log_debug "✅ Home directory updated to version: $IMAGE_FULL_NAME"

    # Debug: mostra cosa è stato copiato
    if [ "${DEBUG:-false}" = "true" ]; then
        log_debug "📂 Home directory contents:"
        ls -la "$HOME_DIR"
        log_debug "📂 .bashrc.d contents:"
        ls -la "$HOME_DIR/.bashrc.d"
    fi
fi

# Applica override user_home ad ogni avvio (se presenti)
if [ -d "/opt/overrides/user_home/$USER" ]; then
  log_debug "🟪 Applying overrides from /opt/overrides/user_home/$USER to $HOME_DIR"
  # Copia sovrascrivendo, preserva permessi/attributi quando possibile
  cp -a "/opt/overrides/user_home/$USER/." "$HOME_DIR/" 2>/dev/null || cp -r "/opt/overrides/user_home/$USER/." "$HOME_DIR/" || true
else
  log_debug "ℹ️  No overrides directory at /opt/overrides/user_home/$USER"
fi

# Crea directory standard se non esistono
mkdir -p "$HOME_DIR/.ssh" "$HOME_DIR/.config" "$HOME_DIR/.local/bin" "$HOME_DIR/.cache"
chmod 700 "$HOME_DIR/.ssh" || true

# Applica override root_home ad ogni avvio (se presenti)
if [ -d /opt/overrides/root_home ]; then
  log_debug "🟥 Applying overrides from /opt/overrides/root_home to /root"
  cp -a /opt/overrides/root_home/. /root/ 2>/dev/null || cp -r /opt/overrides/root_home/. /root/ || true
  # Normalizza permessi minimi di sicurezza comuni (opzionale)
  [ -d /root/.ssh ] && chmod 700 /root/.ssh || true
else
  log_debug "ℹ️  No overrides directory at /opt/overrides/root_home"
fi

. ~/.bashrc.d/load.sh

# Assicura che tutti i file nella home abbiano il proprietario corretto
chown -R $USER:$GROUP "$HOME_DIR"

setup_extra_groups

# Prevent core dumps
ulimit -c 0

log_debug "✅ Privileged operations completed"
log_end_section

# ========================================
# CAMBIO UTENTE (preservando l'ambiente)
# ========================================

# ========================================
# SELEZIONE UTENTE DINAMICA (Rootless/Bind)
# ========================================

log_debug_section "👤 User Selection Logic"

TARGET_UID=$(stat -c '%u' .)
TARGET_GID=$(stat -c '%g' .)

log_debug "📂 Workdir owned by UID: $TARGET_UID, GID: $TARGET_GID"

# Case A: Workdir is owned by root (0).
# This happens in:
# 1. Native Docker, volume explicitly owned by root.
# 2. Rootless Docker, where host user maps to container-root.
if [ "$TARGET_UID" -eq 0 ]; then
    log_debug "🚀 Detected Root ownership (or Rootless mode). Remaining as ROOT."
    
    # Per coerenza, usiamo l'ambiente root
    export HOME="/root"
    cd "${DPM_PROJECT_ROOT}"

    # Carica lib root se esistono; fallback a quelle dell'utente se mancanti
    if [ -f /root/.bashrc.d/load.sh ]; then
        . /root/.bashrc.d/load.sh
    elif [ -f "$HOME_DIR/.bashrc.d/load.sh" ]; then
        log_debug "ℹ️  /root/.bashrc.d/load.sh non presente; carico $HOME_DIR/.bashrc.d/load.sh"
        . "$HOME_DIR/.bashrc.d/load.sh"
    else
        log_warn "⚠️  Nessun load.sh trovato in /root/.bashrc.d o in $HOME_DIR/.bashrc.d"
    fi
    
    echo "� Running as: $(whoami) (UID=$(id -u), GID=$(id -g))"

    if [ -n "${USE_TMUX+x}" ] && [[ "$USE_TMUX" =~ ^(1|true|yes|on)$ ]]; then
        docker_entrypoint_tmux "$@"
    else
        docker_entrypoint_common "$@"
    fi
else
    # Case B: Workdir is owned by a specific UID (not 0).
    # We must match that UID to write.
    
    log_debug "🔄 Matching container user '$USER' to UID $TARGET_UID..."

    CURRENT_UID=$(id -u "$USER")
    CURRENT_GID=$(id -g "$GROUP")

    if [ "$TARGET_UID" != "$CURRENT_UID" ]; then
        log_debug "  ➤ Adjusting UID $CURRENT_UID -> $TARGET_UID"
        usermod -u "$TARGET_UID" "$USER"
        
        # Fix permissions on home dir (recurisve chown is expensive, but necessary if we shift UID)
        # Assuming HOME_DIR is not huge yet (it's a fresh container)
        log_debug "  ➤ Fixing home permissions..."
        chown -R "$USER" "$HOME_DIR"
    fi

    # Group management
    if [ "$TARGET_GID" != "$CURRENT_GID" ]; then
       # Check if GID exists
       if getent group "$TARGET_GID" >/dev/null; then
           log_debug "  ➤ Target GID $TARGET_GID exists. Attaching user to it."
           EXISTING_GRP=$(getent group "$TARGET_GID" | cut -d: -f1)
           usermod -g "$EXISTING_GRP" "$USER"
       else
           log_debug "  ➤ Adjusting GID $CURRENT_GID -> $TARGET_GID"
           groupmod -g "$TARGET_GID" "$GROUP"
       fi
       chown -R :"$TARGET_GID" "$HOME_DIR"
    fi

    log_debug "✅ User adjustment complete"
    log_debug_section "🚀 Avvio sessione utente: $USER"

    if command -v gosu >/dev/null 2>&1; then
        exec gosu "$USER" bash -c '
            export HOME="'"$HOME_DIR"'"
            cd "${DPM_PROJECT_ROOT}"
            
            # Re-source user libs
            . ~/.bashrc.d/load.sh

            echo "👤 Now running as: $(whoami) (UID=$(id -u), GID=$(id -g))"

            if [ -n "${USE_TMUX+x}" ] && [[ "$USE_TMUX" =~ ^(1|true|yes|on)$ ]]; then
                docker_entrypoint_tmux "$@"
            else
                docker_entrypoint_common "$@"
            fi
        ' -- "$@"
    else
        echo "❌ Critical: gosu not found. Cannot drop privileges correctly."
        exit 1
    fi
fi

