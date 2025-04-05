#!/bin/bash

source .env

COMPOSE_FILE="./docker-compose.yml"
ROOT_DIR="dev/docker"
export DOCKER_CONFIG=/workdir/.docker

if [ -z "$DOCKERHUB_USERNAME" ]; then
  echo "❌ Errore: DOCKERHUB_USERNAME non è valorizzata o è vuota!"
  exit 1
else
  echo "✅ DOCKERHUB_USERNAME è valorizzata!"
fi

if [ -z "$DOCKERHUB_TOKEN" ]; then
  echo "❌ Errore: DOCKERHUB_TOKEN non è valorizzata o è vuota!"
  exit 1
else
  echo "✅ DOCKERHUB_TOKEN è valorizzata!"
fi

echo "$DOCKERHUB_TOKEN" | docker login -u "$DOCKERHUB_USERNAME" --password-stdin

echo "docker images------------------------"
docker images

echo "docker compose config------------------------"
docker compose -f "$COMPOSE_FILE" config

echo "docker push------------------------"

#docker compose -f "$COMPOSE_FILE" push

for dir in ${ROOT_DIR}/*/; do
  dir_name=$(basename "$dir")
  docker push ${DOCKERHUB_USERNAME}/${dir_name}
done
