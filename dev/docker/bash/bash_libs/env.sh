#!/usr/bin/env bash

LOGGING_SH_S_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$LOGGING_SH_S_DIR/libs.sh"
lib_guard "ENV_SH" || { return 0 2>/dev/null || exit 0; }

source "$LOGGING_SH_S_DIR/logging.sh"
source "$LOGGING_SH_S_DIR/emoji.sh"

function load_dotenv() {
    local env_file="${1}"
    log_debug_section "$emoji_magnifying_glass_tilted_left Loading: $env_file"

    if [ -f "$env_file" ]; then
        # Metodo alternativo: parsing linea per linea
        while IFS='=' read -r key value; do
            # Salta righe vuote e commenti
            [[ $key =~ ^[[:space:]]*$ ]] && continue
            [[ $key =~ ^[[:space:]]*# ]] && continue

            # Rimuovi spazi bianchi e quotes
            key=$(echo "$key" | xargs)
            value=$(echo "$value" | xargs)

            # Rimuovi eventuali quotes dal valore
            value="${value%\"}"
            value="${value#\"}"
            value="${value%\'}"
            value="${value#\'}"

            # Esporta la variabile
            export "$key"="$value"
            log_debug_env_var "$key"
        done < "$env_file"
        log_debug "${emoji_check_mark_button} done"
    else
        log_debug "${emoji_cross_mark}  File $env_file not found"
    fi
    log_end_section
}
