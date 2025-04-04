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
  full_image_name="${PROJECT_NAME}-${image_name}"

  md5_var="MD5_$(echo "$image_name" | tr '[:lower:]' '[:upper:]')"
  expected_md5=${!md5_var}

  if [ -z "$expected_md5" ]; then
    echo "⚠️  Skippato '$image_name', variabile ambientale '$md5_var' non definita"
    continue
  fi

  image_full="$full_image_name:$expected_md5"

  match=$(echo "$docker_images_json" | jq --arg repo "$full_image_name" --arg tag "$expected_md5" 'map(select(.Repository == $repo and .Tag == $tag)) | length')

  if [ "$match" -eq 0 ]; then
    echo "❌ [$image_full]: immagine mancante o tag differente!"
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
