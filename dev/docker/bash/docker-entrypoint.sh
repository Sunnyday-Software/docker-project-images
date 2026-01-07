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

log_debug_section "Privileged startup operations for: ${IMAGE_FULL_NAME:-unknown image}"

if docker_is_rootless; then
  log_debug "🐳 Docker mode: rootless (userns)"
  export HOME=/home/devuser
  export USER=root
  export ROOTLESS_ENVIRONMENT=true
else
  log_debug "🐳 Docker mode: rootful (o non determinabile)"
  export ROOTLESS_ENVIRONMENT=false
fi

log_debug "🔐 Running as root: $(whoami)"
log_debug "🏠 Current HOME is: $HOME"
log_debug "📂 Current working directory: $(pwd)"


# File marker della versione nella home dell'utente
HOME_VERSION_FILE="$HOME/.image-version"

# Verifica se la home deve essere inizializzata o aggiornata
NEEDS_UPDATE=false

if [ ! -f "$HOME/.bashrc" ] || [ ! -d "$HOME/.bashrc.d" ]; then
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

    if [ -d "$HOME" ]; then
        mkdir -p "$TEMP_BACKUP"
        for dir in "${BACKUP_DIRS[@]}"; do
            if [ -d "$HOME/$dir" ]; then
                echo "💾 Backing up $dir"
                cp -a "$HOME/$dir" "$TEMP_BACKUP/" || true
            fi
        done
    fi

    # Rimuove i file template vecchi (ma preserva i backup)
    log_debug "🧹 Cleaning old template files..."
    find "$HOME" -mindepth 1 -maxdepth 1 ! -name '.ssh' ! -name '.config' ! -name '.cache' -exec rm -rf {} + 2>/dev/null || true

    # Copia il nuovo template
    log_debug "📋 Copying new template..."
    cp -a /opt/home-template/. "$HOME/"

    # Ripristina i backup
    if [ -d "$TEMP_BACKUP" ]; then
        for dir in "${BACKUP_DIRS[@]}"; do
            if [ -d "$TEMP_BACKUP/$dir" ]; then
                log_debug "♻️  Restoring $dir"
                cp -an "$TEMP_BACKUP/$dir/." "$HOME/$dir/" 2>/dev/null || true
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
        ls -la "$HOME"
        log_debug "📂 .bashrc.d contents:"
        ls -la "$HOME/.bashrc.d"
    fi
fi

# Applica override user_home ad ogni avvio (se presenti)
if [ -d "/opt/overrides/user_home/$USER" ]; then
  log_debug "🟪 Applying overrides from /opt/overrides/user_home/$USER to $HOME"
  # Copia sovrascrivendo, preserva permessi/attributi quando possibile
  cp -a "/opt/overrides/user_home/$USER/." "$HOME/" 2>/dev/null || cp -r "/opt/overrides/user_home/$USER/." "$HOME/" || true
else
  log_debug "ℹ️  No overrides directory at /opt/overrides/user_home/$USER"
fi

# Crea directory standard se non esistono
mkdir -p "$HOME/.ssh" "$HOME/.config" "$HOME/.local/bin" "$HOME/.cache"
chmod 700 "$HOME/.ssh" || true

# Applica override root_home ad ogni avvio (se presenti)
# if  [ -d /opt/overrides/root_home ]; then
#   log_debug "🟥 Applying overrides from /opt/overrides/root_home to /root"
#   cp -a /opt/overrides/root_home/. /root/ 2>/dev/null || cp -r /opt/overrides/root_home/. /root/ || true
#   # Normalizza permessi minimi di sicurezza comuni (opzionale)
#   [ -d /root/.ssh ] && chmod 700 /root/.ssh || true
# else
#   log_debug "ℹ️  No overrides directory at /opt/overrides/root_home"
# fi

#. ~/.bashrc.d/load.sh

# Assicura che i file nella home abbiano il proprietario corretto in modo efficiente
if [ "${DPM_SKIP_CHOWN:-0}" != "1" ]; then
    log_debug "⚖️  Verifica permessi directory HOME (selettivo)..."
    # Cambia proprietario solo se necessario per evitare rallentamenti su volumi grandi
    find "$HOME" \
        \( -path "$HOME/.cache" -o -path "$HOME/.npm" -o -path "$HOME/.maven" -o -path "$HOME/.gradle" \) -prune \
        -o ! -user "$USER" -exec chown "$USER:$GROUP" {} + 2>/dev/null || true
    
    # Assicura che almeno la radice della home e i file critici siano corretti
    chown "$USER:$GROUP" "$HOME" "$HOME/.ssh" "$HOME/.bashrc" "$HOME/.bashrc.d" 2>/dev/null || true
else
    log_debug "⏭️  Skip chown della HOME (DPM_SKIP_CHOWN=1)"
fi

setup_extra_groups

# Prevent core dumps
ulimit -c 0

log_debug "✅ Privileged operations completed"
log_end_section

# ========================================
# CAMBIO UTENTE (preservando l'ambiente)
# ========================================

if [ "$ROOTLESS_ENVIRONMENT" = "true" ]; then
      log_debug_section "👤 Rootless environment"

      # Fallback: niente cambio utente, ma normalizzi comunque HOME e cwd
      export HOME="$HOME"
      cd "${DPM_PROJECT_ROOT}"

      log_info "👤 Rootless user: $(whoami) (UID=$(id -u), GID=$(id -g))"
      log_info "🏠 HOME is now: $HOME"
      log_info "📂 Working directory is now: $(pwd)"

      [ -f "$HOME/.bashrc.d/load.sh" ] && . "$HOME/.bashrc.d/load.sh"

      docker_entrypoint_common "$@"
else
  log_debug_section "👤 Switching to user: $USER"
  exec gosu "$USER" bash -c '
      export HOME="'"$HOME"'"
      # Cambia esplicitamente alla directory di lavoro
      cd ${DPM_PROJECT_ROOT}

      echo "👤 Now running as: $(whoami) (UID=$(id -u), GID=$(id -g))"
      echo "🏠 HOME is now: $HOME"
      echo "📂 Working directory is now: $(pwd)"

      # Esegue il comando finale
      [ -f "$HOME/.bashrc.d/load.sh" ] && . "$HOME/.bashrc.d/load.sh"

      docker_entrypoint_common "$@"
  ' -- "$@"
fi

