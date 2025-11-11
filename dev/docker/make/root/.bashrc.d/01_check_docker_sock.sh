#!/usr/bin/env bash

# debug docker.sock inside "make" container

# carica le libs, se disponibili
if [ -r "/opt/bash_libs/import_libs.sh" ]; then
  # shellcheck disable=SC1091
  source "/opt/bash_libs/import_libs.sh"
fi

BRC_ROOT_CHECK_DOCKER_SOCK_SH_S_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
lib_guard "BRC_ROOT_CHECK_DOCKER_SOCK_SH_S_DIR" || { return 0 2>/dev/null || exit 0; }

HOOK_NAME="${1:-docker-sock-check}"
SOCKET_PATH="/var/run/docker.sock"

log_info "=========================================="
log_info "Docker Socket Debug Script (${HOOK_NAME})"
log_info "=========================================="

# 1. Verifica esistenza socket
log_debug "1. Verifica esistenza socket: $SOCKET_PATH"
if [ -e "$SOCKET_PATH" ]; then
  log_debug "   ✓ Socket exists"
else
  log_warn "   ✗ Socket NOT found"
  # non usciamo con errore duro: lasciamo continuare il container
fi

# 2. Tipo file
log_debug "2. Tipo file:"
if [ -e "$SOCKET_PATH" ]; then
  file "$SOCKET_PATH" 2>/dev/null | log_debug
  if [ -S "$SOCKET_PATH" ]; then
    log_debug "   ✓ Is a socket"
  else
    log_warn "   ✗ NOT a socket!"
  fi
else
  log_debug "   (skip: file non esiste)"
fi

# 3. Permessi e ownership
log_debug "3. Permessi e ownership:"
if [ -e "$SOCKET_PATH" ]; then
  ls -lh "$SOCKET_PATH" 2>/dev/null | log_debug
  stat "$SOCKET_PATH" 2>/dev/null | log_debug || stat -x "$SOCKET_PATH" 2>/dev/null | log_debug || true
else
  log_debug "   (skip: file non esiste)"
fi

# 4. UID/GID numerico
log_debug "4. UID/GID numerico:"
if [ -e "$SOCKET_PATH" ]; then
  if command -v stat >/dev/null 2>&1; then
    SOCK_UID=$(stat -c '%u' "$SOCKET_PATH" 2>/dev/null || stat -f '%u' "$SOCKET_PATH" 2>/dev/null)
    SOCK_GID=$(stat -c '%g' "$SOCKET_PATH" 2>/dev/null || stat -f '%g' "$SOCKET_PATH" 2>/dev/null)
    log_debug "   UID: $SOCK_UID"
    log_debug "   GID: $SOCK_GID"
    if [ -n "$SOCK_GID" ]; then
      export DPM_USER_ADD_GID_S_LIST="${SOCK_GID}${DPM_USER_ADD_GID_S_LIST:+,${DPM_USER_ADD_GID_S_LIST}}"
      log_debug "   ➤ DPM_USER_ADD_GID_S_LIST=$DPM_USER_ADD_GID_S_LIST"
    fi
  else
    log_warn "   stat non disponibile"
  fi
else
  log_debug "   (skip: file non esiste)"
fi

# 5. Utente corrente
log_debug "5. Utente corrente nel container:"
whoami 2>/dev/null | log_debug
id 2>/dev/null | log_debug

# 6. Test lettura/scrittura
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

# 7. Test HTTP raw
log_debug "7. Test connessione HTTP raw al socket:"
if command -v curl >/dev/null 2>&1 && [ -S "$SOCKET_PATH" ]; then
  log_debug "   Tentativo: curl --unix-socket $SOCKET_PATH http://localhost/_ping"
  curl --unix-socket "$SOCKET_PATH" http://localhost/_ping 2>&1 | log_debug
else
  log_debug "   curl non disponibile o socket assente, skip"
fi

# 8. Test docker CLI
log_debug "8. Test connessione con docker CLI:"
if command -v docker >/dev/null 2>&1 && [ -S "$SOCKET_PATH" ]; then
  export DOCKER_HOST="unix://$SOCKET_PATH"
  log_debug "   DOCKER_HOST=$DOCKER_HOST"
  docker version 2>&1 | log_debug || log_warn "   ✗ docker version fallita"
  # info breve
  docker info --format '{{.ServerVersion}}' 2>/dev/null | log_debug || true
else
  log_debug "   docker CLI non disponibile o socket assente"
fi

# 9. Env docker
log_debug "9. Variabili d'ambiente Docker:"
env | grep -i docker | log_debug || log_debug "   Nessuna variabile DOCKER_* trovata"

# 10. Siamo dentro un container?
log_debug "10. Siamo dentro un container?"
if [ -f /.dockerenv ]; then
  log_debug "   ✓ Sì (/.dockerenv)"
elif grep -q docker /proc/1/cgroup 2>/dev/null; then
  log_debug "   ✓ Sì (cgroup)"
else
  log_debug "   ? Forse no"
fi

log_info "=========================================="
log_info "Fine diagnostica docker.sock"
log_info "=========================================="
