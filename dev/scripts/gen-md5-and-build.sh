#!/bin/bash

COMPOSE_FILE="docker-compose.yml"
ROOT_DIR="dev/docker"

# entra nella cartella root di docker build
cd "$ROOT_DIR" || { echo "Directory non trovata: $ROOT_DIR"; exit 1; }

# Calcola e esporta variabili MD5 abbreviate a 10 caratteri
for dir in */; do
  dir_name=$(basename "$dir")

  # hash MD5 ridotto a 10 caratteri, checksum stabile anche per nome-filename ordinamento
  DIR_HASH=$(find "$dir" -type f -exec md5sum {} \; | sort | md5sum | awk '{print substr($1,1,10)}')

  VAR_NAME="MD5_$(echo "$dir_name" | tr '[:lower:]-' '[:upper:]_')"
  export "${VAR_NAME}"="${DIR_HASH}"

  echo "✅ Variabile ambientale esportata: ${VAR_NAME}=${DIR_HASH}"
done

# torna indietro alla cartella del progetto
cd - >/dev/null || exit 1

# build delle immagini utilizzando docker compose:
echo "🐳 Docker Compose: BUILD"
docker compose -f "$COMPOSE_FILE" build

# opzionalmente, se vuoi anche pushare automaticamente dopo la build:
echo "🐳 Docker Compose: PUSH"
docker compose -f "$COMPOSE_FILE" push