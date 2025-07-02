#!/bin/bash

BASE_PATH="./dev/docker"
BUILD_NECESSARIA=0  # flag per indicare se dobbiamo triggerare una build finale

if [ ! -d "$BASE_PATH" ]; then
  echo "❌ Directory '$BASE_PATH' non trovata!"
  exit 1
fi

if [ -z "$PROJECT_NAME" ]; then
  echo "❌ La variabile ambientale PROJECT_NAME non è definita. Interrompo lo script!"
  exit 1
fi

# Elenco immagini docker corrente (in JSON)
docker_images_json=$(docker images --format '{{json .}}' | jq -s '.')

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



  match=$(echo "$docker_images_json" | jq --arg repo "$full_image_name" --arg tag "${expected_checksum}-${PLATFORM_TAG}" 'map(select(.Repository == $repo and .Tag == $tag)) | length')

  if [ "$match" -eq 0 ]; then
    echo "❌ [$image_full]: immagine mancante o tag differente!"
    echo "  checksum_var:${checksum_var}"
    echo "  checksum:${expected_checksum}"

    BUILD_NECESSARIA=1
  else
    echo "✅ [$image_full]: già presente, tutto OK."
  fi

done

# Se necessario, delega la build allo script dedicato
if [ "$BUILD_NECESSARIA" -eq 1 ]; then
  echo -e "\n⚠️  Una o più immagini sono mancanti o incoerenti.\n🚀 Eseguo build completa tramite lo script 'build-images.sh'!"
  ./dev/scripts/docker_build_images.sh
else
  echo -e "\n✅ Tutte le immagini sono coerenti. Nessuna build necessaria."
fi
