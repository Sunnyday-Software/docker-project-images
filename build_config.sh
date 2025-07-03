#!/bin/bash

# Configurazione delle immagini Docker
# Ogni immagine è definita come un array associativo con:
# - name: nome dell'immagine
# - platforms: piattaforme supportate (amd64, arm64, o entrambe)
# - depends_on: dipendenze da altre immagini (opzionale)
# - build_args: argomenti di build (opzionale)

declare -A IMAGE_BASH=(
    [name]="bash"
    [platforms]="amd64,arm64"
    [dockerfile]="dev/docker/bash/Dockerfile"
    [context]="dev/docker/bash"
    [build_args]=""
)

declare -A IMAGE_MAKE=(
    [name]="make"
    [platforms]="amd64,arm64"
    [dockerfile]="dev/docker/make/Dockerfile"
    [context]="dev/docker/make"
    [depends_on]="bash"
    [build_args]=""
)

declare -A IMAGE_OPENTOFU=(
    [name]="opentofu"
    [platforms]="amd64,arm64"
    [dockerfile]="dev/docker/opentofu/Dockerfile"
    [context]="dev/docker/opentofu"
    [depends_on]="bash"
    [build_args]="OPENTOFU_RELEASE=${OPENTOFU_RELEASE:-1.9.0}"
)

# Ordine di build delle immagini
BUILD_ORDER=(
    "IMAGE_BASH"
    "IMAGE_MAKE"
    "IMAGE_OPENTOFU"
)

# Funzione per ottenere le informazioni di un'immagine
get_image_info() {
    local image_ref="$1"
    local -n image_data=$image_ref
    echo "${image_data[@]}"
}

# Funzione per verificare se un'immagine supporta una piattaforma
supports_platform() {
    local image_ref="$1"
    local platform="$2"
    local -n image_data=$image_ref
    
    [[ "${image_data[platforms]}" == *"$platform"* ]]
}

# Funzione per ottenere le dipendenze di un'immagine
get_dependencies() {
    local image_ref="$1"
    local -n image_data=$image_ref
    
    echo "${image_data[depends_on]:-}"
}
