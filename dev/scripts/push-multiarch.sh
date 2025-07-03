#!/bin/bash

# Source the error handler
source "$(dirname "$0")/error_handler.sh"

source .env
source "$(dirname "$0")/../../build_config.sh"

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

# Funzione per verificare se un'immagine è multipiattaforma
is_multiplatform() {
  local image_name="$1"
  local image_ref="IMAGE_$(echo "$image_name" | tr '[:lower:]' '[:upper:]')"

  # Verifica se l'immagine esiste nella configurazione
  if declare -p "$image_ref" &>/dev/null; then
    local -n image_data=$image_ref
    local platforms="${image_data[platforms]}"
    # È multipiattaforma se contiene sia amd64 che arm64
    [[ "$platforms" == *"amd64"* && "$platforms" == *"arm64"* ]]
  else
    # Default: assume multipiattaforma se non trovata nella configurazione
    return 0
  fi
}

# Ciclo sulle sotto-cartelle per verificare coerenza immagini docker
for folder in "$BASE_PATH"/*/; do
  folder=${folder%/}  # rimuove eventuale slash finale
  image_name=$(basename "$folder" | tr '[:upper:]' '[:lower:]')
  normalized_name=$(basename "$folder" | tr '[:lower:]' '[:upper:]' | sed 's/[^[:alnum:]]/_/g')
  full_image_name="${DOCKERHUB_USERNAME}/${image_name}"

  checksum_var="${normalized_name}_CHECKSUM"
  expected_checksum=${!checksum_var}

  version_var="${normalized_name}_VERSION"
  expected_version="v-${!version_var}"

  echo "=================================================="
  echo "folder: $folder"
  echo "image_name: $image_name"
  echo "normalized_name: $normalized_name"
  echo "full_image_name: $full_image_name"
  echo "checksum_var: $checksum_var"
  echo "expected_checksum: $expected_checksum"
  echo ""

  # Verifica se l'immagine è multipiattaforma
  if is_multiplatform "$image_name"; then
    echo "🏗️  Immagine multipiattaforma: $image_name"
    echo "📦 Creazione manifesti per amd64 e arm64..."

    # Crea manifesto per checksum tag
    echo "📋 ${full_image_name}:${expected_checksum}"
    docker manifest create "${full_image_name}:${expected_checksum}" \
      "${full_image_name}:${expected_checksum}-amd64" \
      "${full_image_name}:${expected_checksum}-arm64"
    docker manifest push "${full_image_name}:${expected_checksum}"

    # Crea manifesto per version tag
    echo "📋 ${full_image_name}:${expected_version}"
    docker manifest create "${full_image_name}:${expected_version}" \
      "${full_image_name}:${expected_checksum}-amd64" \
      "${full_image_name}:${expected_checksum}-arm64"
    docker manifest push "${full_image_name}:${expected_version}"

    # Crea manifesto per latest tag
    echo "📋 ${full_image_name}:latest"
    docker manifest create "${full_image_name}:latest" \
      "${full_image_name}:${expected_checksum}-amd64" \
      "${full_image_name}:${expected_checksum}-arm64"
    docker manifest push "${full_image_name}:latest"

  else
    echo "🔧 Immagine single-platform: $image_name"
    echo "🏷️  Tagging solo con latest (assumendo amd64)..."

    # Per immagini single-platform, tagga solo l'immagine esistente come latest
    single_platform_tag="${full_image_name}:${expected_checksum}-amd64"

    echo "🏷️  Tagging ${single_platform_tag} come latest"
    docker tag "$single_platform_tag" "${full_image_name}:latest"
    docker push "${full_image_name}:latest"

    # Tagga anche con version
    echo "🏷️  Tagging ${single_platform_tag} come ${expected_version}"
    docker tag "$single_platform_tag" "${full_image_name}:${expected_version}"
    docker push "${full_image_name}:${expected_version}"
  fi

done
