#!/bin/bash
set -e

function ci_config {
  local appuser="bashuser"
  local appgroup="bashuser"

  # UID/GID del runner (GitHub Actions solitamente è 1001, ma qui lo recuperiamo dinamicamente)
  TARGET_UID=$(id -u)
  TARGET_GID=$(id -g)

  # UID/GID attuali dell'utente dentro il container
  CURRENT_UID=$(id -u $appuser)
  CURRENT_GID=$(id -g $appuser)

  # Cambia UID/GID dell'utente solo se necessario (solitamente container avrà privilegi sufficienti per questa operazione iniziale)
  if [ "$TARGET_UID" != "$CURRENT_UID" ] || [ "$TARGET_GID" != "$CURRENT_GID" ]; then
      echo "Modifica UID/GID interni da $CURRENT_UID/$CURRENT_GID a $TARGET_UID/$TARGET_GID"
      deluser $appuser
      addgroup -g "$TARGET_GID" $appgroup
      adduser -u "$TARGET_UID" -G $appgroup -D $appuser

      # Imposta i permessi nuovamente sui volumi montati/directory importanti
      chown -R $appuser:$appgroup /app
  fi

}


if [ "$CI" == "true" ]; then
    echo "Ambiente CI rilevato"
    ci_config
fi