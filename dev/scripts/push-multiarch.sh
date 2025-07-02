#!/bin/bash

# Source the error handler
source "$(dirname "$0")/error_handler.sh"

source .env

COMPOSE_FILE="./docker-compose.yml"
export DOCKER_CONFIG=/workdir/.docker

if [ -z "$DOCKERHUB_USERNAME" ]; then
  echo "❌ Errore: DOCKERHUB_USERNAME non è valorizzata o è vuota!"
  exit 1
else
  echo "✅ DOCKERHUB_USERNAME è valorizzata!"
fi


echo "$DOCKERHUB_TOKEN" | docker login -u "$DOCKERHUB_USERNAME" --password-stdin


BASE_PATH="./dev/docker"

if [ ! -d "$BASE_PATH" ]; then
  echo "❌ Directory '$BASE_PATH' non trovata!"
  exit 1
fi

# Ciclo sulle sotto-cartelle per verificare coerenza immagini docker
for folder in "$BASE_PATH"/*/; do
  folder=${folder%/}  # rimuove eventuale slash finale
  image_name=$(basename "$folder" | tr '[:upper:]' '[:lower:]')
  normalized_name=$(basename "$folder" | tr '[:lower:]' '[:upper:]' | sed 's/[^[:alnum:]]/_/g')
  full_image_name="${DOCKERHUB_USERNAME}/${image_name}"

  checksum_var="${normalized_name}_CHECKSUM"
  expected_checksum=${!checksum_var}
  image_full="${full_image_name}:${expected_checksum}-${PLATFORM_TAG}"

  echo "folder: $folder"
  echo "image_name: $image_name"
  echo "normalized_name: $normalized_name"
  echo "full_image_name: $full_image_name"
  echo "checksum_var: $checksum_var"
  echo "expected_checksum: $expected_checksum"
  echo "image_full: $image_full"

  if [ -z "${expected_checksum}" ]; then
    echo "⚠️  Ignoro '$image_name', variabile ambientale '$checksum_var' non definita"
    continue
  fi

docker manifest create "${full_image_name}:${expected_checksum}" \
  "${full_image_name}:${expected_checksum}-amd64" \
  "${full_image_name}:${expected_checksum}-arm64"

docker manifest create "${full_image_name}:latest" \
  "${full_image_name}:${expected_checksum}-amd64" \
  "${full_image_name}:${expected_checksum}-arm64"

docker manifest push "${full_image_name}:${expected_checksum}"
docker manifest push "${full_image_name}:latest"

done

