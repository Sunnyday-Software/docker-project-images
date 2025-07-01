#!/bin/bash

# Source the error handler
source "$(dirname "$0")/error_handler.sh"

COMPOSE_FILE="docker-compose.yml"
ROOT_DIR="dev/docker"

# entra nella cartella root di docker build
cd "$ROOT_DIR" || { echo "Directory non trovata: $ROOT_DIR"; exit 1; }


# torna indietro alla cartella del progetto
cd - >/dev/null || exit 1

# build delle immagini utilizzando docker compose:
echo "🐳 Docker Compose: BUILD bash first"
docker compose -f "$COMPOSE_FILE" build bash
echo "🐳 Docker Compose: BUILD remaining images"
docker compose -f "$COMPOSE_FILE" build

# opzionalmente, se vuoi anche pushare automaticamente dopo la build:
#echo "🐳 Docker Compose: PUSH"
#docker compose -f "$COMPOSE_FILE" push
