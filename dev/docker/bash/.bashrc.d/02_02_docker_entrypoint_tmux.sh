#!/bin/bash

set -e

source "/opt/bash_libs/import_libs.sh"
BRC_DOCKER_ENTRYPOINT_TMUX_SH_S_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
lib_guard "BRC_DOCKER_ENTRYPOINT_TMUX_SH_S_DIR" || { return 0 2>/dev/null || exit 0; }


# Avvia o riutilizza una sessione tmux per eseguire il comando passato.
# Variabili:
#   TMUX_SESSION_NAME: nome della sessione (default: dev)
#   TMUX_WINDOW_NAME:  nome della window (default: main)
#   TMUX_DETACH:       se "true", stacca subito dopo l’avvio (default: true)

function docker_entrypoint_tmux {

    local S="${TMUX_SESSION_NAME:-dev}"
    local W="${TMUX_WINDOW_NAME:-main}"
    local SOCKET="${TMUX_SOCKET_NAME:-dpm}"
    local DETACH="${TMUX_DETACH:-true}"
    local cmd=("$@")
    # Se non c'è comando, apri shell di login
    if [ ${#cmd[@]} -eq 0 ]; then
        cmd=(bash -l)
    fi

    # Non ereditare un TMUX esterno
    unset TMUX

    # Avvia una sessione con il comando come *programma* della window
    # NB: "exec" rimpiazza la shell della window con il tuo comando
    tmux -L "$SOCKET" new-session -d -s "$S" -n "$W" "exec $(printf '%q ' "${cmd[@]}")"

    # Opzioni: chiudi server quando non ci sono sessioni; non lasciare window in remain-on-exit
    tmux -L "$SOCKET" set -g exit-empty on   >/dev/null 2>&1 || true
    tmux -L "$SOCKET" setw -t "$S:$W" remain-on-exit off >/dev/null 2>&1 || true

    if [ "$DETACH" = "false" ]; then
        exec tmux -L "$SOCKET" attach -t "$S"
    fi

    # 👉 stampa i comandi utili per collegarti
    local attach_in="tmux -L ${SOCKET} attach -t ${S}"
    log_info "Per collegarti alla sessione tmux:"
    log_info "  • dentro al container: ${attach_in}"
    if [ -n "${DPM_RUN_IMAGE:-}" ]; then
        log_info "  • dall'host con Docker Compose:"
        log_info "    docker compose exec ${DPM_RUN_IMAGE} ${attach_in}"
    fi

    # Tieni vivo il container finché esiste la sessione
    while tmux -L "$SOCKET" has-session -t "$S" 2>/dev/null; do sleep 1; done
}
