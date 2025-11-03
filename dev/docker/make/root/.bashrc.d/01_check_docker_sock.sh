#!/bin/bash

echo "=========================================="
echo "Docker Socket Debug Script"
echo "=========================================="
echo

# 1. Verifica esistenza socket
SOCKET_PATH="/var/run/docker.sock"
echo "1. Verifica esistenza socket: $SOCKET_PATH"
if [ -e "$SOCKET_PATH" ]; then
  echo "   ✓ Socket exists"
else
  echo "   ✗ Socket NOT found"
  exit 1
fi
echo

# 2. Verifica tipo file (deve essere socket)
echo "2. Tipo file:"
file "$SOCKET_PATH"
if [ -S "$SOCKET_PATH" ]; then
  echo "   ✓ Is a socket"
else
  echo "   ✗ NOT a socket!"
  exit 1
fi
echo

# 3. Permessi dettagliati
echo "3. Permessi e ownership:"
ls -lh "$SOCKET_PATH"
stat "$SOCKET_PATH" 2>/dev/null || stat -x "$SOCKET_PATH" 2>/dev/null
echo

# 4. Ownership numerico (UID/GID)
echo "4. UID/GID numerico:"
if command -v stat >/dev/null 2>&1; then
  # Linux
  SOCK_UID=$(stat -c '%u' "$SOCKET_PATH" 2>/dev/null || stat -f '%u' "$SOCKET_PATH" 2>/dev/null)
  SOCK_GID=$(stat -c '%g' "$SOCKET_PATH" 2>/dev/null || stat -f '%g' "$SOCKET_PATH" 2>/dev/null)
  echo "   UID: $SOCK_UID"
  echo "   GID: $SOCK_GID"
  EXTRA_GID="$SOCK_GID,$EXTRA_GID"
fi
echo

# 5. Utente corrente
echo "5. Utente corrente nel container:"
whoami
id
echo

# 6. Test di lettura/scrittura
echo "6. Test accesso in lettura/scrittura:"
if [ -r "$SOCKET_PATH" ]; then
  echo "   ✓ Readable"
else
  echo "   ✗ NOT readable"
fi

if [ -w "$SOCKET_PATH" ]; then
  echo "   ✓ Writable"
else
  echo "   ✗ NOT writable"
fi
echo

# 7. Test connessione raw con netcat/curl
echo "7. Test connessione HTTP raw al socket:"
if command -v curl >/dev/null 2>&1; then
  echo "   Tentativo: curl --unix-socket $SOCKET_PATH http://localhost/_ping"
  curl --unix-socket "$SOCKET_PATH" http://localhost/_ping 2>&1
  CURL_EXIT=$?
  echo "   Exit code: $CURL_EXIT"
else
  echo "   curl non disponibile, skip"
fi
echo

# 8. Test con docker CLI (se disponibile)
echo "8. Test connessione con docker CLI:"
if command -v docker >/dev/null 2>&1; then
  export DOCKER_HOST="unix://$SOCKET_PATH"
  echo "   DOCKER_HOST=$DOCKER_HOST"
  echo "   Comando: docker version"
  docker version 2>&1
  DOCKER_EXIT=$?
  echo "   Exit code: $DOCKER_EXIT"

  if [ $DOCKER_EXIT -eq 0 ]; then
    echo "   ✓ Docker CLI può connettersi!"
    echo
    echo "   Comando: docker info (breve)"
    docker info --format '{{.ServerVersion}}' 2>&1
  else
    echo "   ✗ Docker CLI fallisce"
  fi
else
  echo "   docker CLI non disponibile"
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
