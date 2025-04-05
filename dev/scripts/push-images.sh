#!/bin/bash

source .env

COMPOSE_FILE="./docker-compose.yml"
ROOT_DIR="dev/docker"


tree -pug
docker compose -f "$COMPOSE_FILE" push

# entra nella cartella root di docker build
#cd "$ROOT_DIR" || { echo "Directory non trovata: $ROOT_DIR"; exit 1; }
#
#for dir in */; do
#  dir_name=$(basename "$dir")
#  docker compose -f "$COMPOSE_FILE" push ${dir_name} --include-deps
#done

