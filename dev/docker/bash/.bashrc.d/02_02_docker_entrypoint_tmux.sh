#!/bin/bash

set -e

source "/opt/bash_libs/import_libs.sh"
BRC_DOCKER_ENTRYPOINT_TMUX_SH_S_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
lib_guard "BRC_DOCKER_ENTRYPOINT_TMUX_SH_S_DIR" || { return 0 2>/dev/null || exit 0; }


function docker_entrypoint_tmux {
  # Avvia o riutilizza una sessione tmux per eseguire il comando passato.
  # Variabili:
  #   TMUX_SESSION_NAME: nome della sessione (default: dev)
  #   TMUX_WINDOW_NAME:  nome della window (default: main)
  #   TMUX_DETACH:       se "true", stacca subito dopo l’avvio (default: true)

  local session_name="${TMUX_SESSION_NAME:-dev}"
  local window_name="${TMUX_WINDOW_NAME:-main}"
  local detach="${TMUX_DETACH:-true}"

  # Assicura che tmux sia disponibile
  if ! command -v tmux >/dev/null 2>&1; then
    log_err "Errore: tmux non trovato nel PATH." >&2
    return 127
  fi

  # Crea la sessione se non esiste
  if ! tmux has-session -t "${session_name}" 2>/dev/null; then
    tmux new-session -d -s "${session_name}" -n "${window_name}"
  fi

  # Se la window esiste già, usala; altrimenti creala
  if ! tmux list-windows -t "${session_name}" -F '#W' 2>/dev/null | grep -qx "${window_name}"; then
    tmux new-window -t "${session_name}" -n "${window_name}"
  fi

  # Invia il comando alla window specificata
  local cmd=("$@")
  if [ ${#cmd[@]} -eq 0 ]; then
    log_debug "Nessun comando specificato. Avvio shell interattiva nella sessione tmux '${session_name}'." >&2
    cmd=("bash" "-l")
  fi

  # Pulisce eventuale job precedente lasciando il prompt pronto
  tmux send-keys -t "${session_name}:${window_name}" C-c

  # Invia il comando e un invio finale
  tmux send-keys -t "${session_name}:${window_name}" "$(printf '%q ' "${cmd[@]}")" C-m

  # Se richiesto, attacca in foreground così il processo PID 1 resta vivo
  if [ "${detach}" = "false" ]; then
    exec tmux attach -t "${session_name}"
  fi

  # Modalità detach: lascia la sessione viva e non chiudere subito la funzione
  # Rimani in attesa finché la sessione esiste, così il container non esce
  log_info "Comando inviato alla sessione tmux '${session_name}'."
  log_info "Per collegarti: tmux attach -t ${session_name}"
  while tmux has-session -t "${session_name}" 2>/dev/null; do
    sleep 2
  done

  # Se la sessione termina, esci
  return 0
}
