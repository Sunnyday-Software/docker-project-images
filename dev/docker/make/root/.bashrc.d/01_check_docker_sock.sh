#!/bin/bash

source "/opt/bash_libs/import_libs.sh"
BRC_ROOT_CHECK_DOCKER_SOCK_SH_S_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
lib_guard "BRC_ROOT_CHECK_DOCKER_SOCK_SH_S_DIR" || { return 0 2>/dev/null || exit 0; }

if log_is_debug_enabled; then

  log_debug_section "Docker Socket Debug Script"

  # 1. Verifica esistenza socket
  SOCKET_PATH="/var/run/docker.sock"
  log_debug "1. Verifica esistenza socket: $SOCKET_PATH"
  if [ -e "$SOCKET_PATH" ]; then
    log_debug "   ✓ Socket exists"
  else
    log_debug "   ✗ Socket NOT found"
    exit 1
  fi


  # 2. Verifica tipo file (deve essere socket)
  log_debug "2. Tipo file:"
  file "$SOCKET_PATH"
  if [ -S "$SOCKET_PATH" ]; then
    log_debug "   ✓ Is a socket"
  else
    log_debug "   ✗ NOT a socket!"
    exit 1
  fi
  echo

  # 3. Permessi dettagliati
  log_debug "3. Permessi e ownership:"
  ls -lh "$SOCKET_PATH"
  stat "$SOCKET_PATH" 2>/dev/null || stat -x "$SOCKET_PATH" 2>/dev/null


  # 4. Ownership numerico (UID/GID)
  log_debug "4. UID/GID numerico:"
  if command -v stat >/dev/null 2>&1; then
    # Linux
    SOCK_UID=$(stat -c '%u' "$SOCKET_PATH" 2>/dev/null || stat -f '%u' "$SOCKET_PATH" 2>/dev/null)
    SOCK_GID=$(stat -c '%g' "$SOCKET_PATH" 2>/dev/null || stat -f '%g' "$SOCKET_PATH" 2>/dev/null)
    log_debug "   UID: $SOCK_UID"
    log_debug "   GID: $SOCK_GID"
    DPM_USER_ADD_GID_S_LIST="$SOCK_GID,$DPM_USER_ADD_GID_S_LIST"
  fi


  # 5. Utente corrente
  log_debug "5. Utente corrente nel container:"
  whoami
  id


  # 6. Test di lettura/scrittura
  log_debug "6. Test accesso in lettura/scrittura:"
  if [ -r "$SOCKET_PATH" ]; then
    log_debug "   ✓ Readable"
  else
    log_debug "   ✗ NOT readable"
  fi

  if [ -w "$SOCKET_PATH" ]; then
    log_debug "   ✓ Writable"
  else
    log_debug "   ✗ NOT writable"
  fi
  echo

  # 7. Test connessione raw con netcat/curl
  echo "7. Test connessione HTTP raw al socket:"
  if command -v curl >/dev/null 2>&1; then
    log_debug "   Tentativo: curl --unix-socket $SOCKET_PATH http://localhost/_ping"
    curl --unix-socket "$SOCKET_PATH" http://localhost/_ping 2>&1
    CURL_EXIT=$?
    log_debug "   Exit code: $CURL_EXIT"
  else
    log_debug "   curl non disponibile, skip"
  fi
  echo

  # 8. Test con docker CLI (se disponibile)
  echo "8. Test connessione con docker CLI:"
  if command -v docker >/dev/null 2>&1; then
    export DOCKER_HOST="unix://$SOCKET_PATH"
    log_debug "   DOCKER_HOST=$DOCKER_HOST"
    log_debug "   Comando: docker version"
    docker version 2>&1
    DOCKER_EXIT=$?
    log_debug "   Exit code: $DOCKER_EXIT"

    if [ $DOCKER_EXIT -eq 0 ]; then
      log_debug "   ✓ Docker CLI può connettersi!"
      echo
      log_debug "   Comando: docker info (breve)"
      docker info --format '{{.ServerVersion}}' 2>&1
    else
      log_debug "   ✗ Docker CLI fallisce"
    fi
  else
    log_debug "   docker CLI non disponibile"
  fi
  echo

  # 9. Verifica variabili d'ambiente
  echo "9. Variabili d'ambiente Docker:"
  env | grep -i docker || echo "   Nessuna variabile DOCKER_* trovata"
  echo

  # 10. Controlla se dentro un container Docker (meta)
  echo "10. Siamo dentro un container?"
  if [ -f /.dockerenv ]; then
    echo "   ✓ Sì (file /.dockerenv esiste)"
  elif grep -q docker /proc/1/cgroup 2>/dev/null; then
    echo "   ✓ Sì (cgroup indica docker)"
  else
    echo "   ? Forse no"
  fi
  echo

  echo "=========================================="
  echo "Fine diagnostica"
  echo "=========================================="

fi