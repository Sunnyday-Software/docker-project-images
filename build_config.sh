#!/usr/bin/env bash

# Configurazione delle immagini Docker
# Ogni immagine è definita come un array associativo con:
# - name: nome dell'immagine
# - platforms: piattaforme supportate (amd64, arm64, o entrambe)
# - depends_on: dipendenze da altre immagini (opzionale)
# - build_args: argomenti di build completi chiave=valore (opzionale)
# - env_to_args: lista di variabili ambientali da trasformare in --build-arg (opzionale)

declare -A IMAGE_BASH=(
    [name]="bash"
    [platforms]="arm64,amd64"
    [dockerfile]="dev/docker/bash/Dockerfile"
    [context]="dev/docker/bash"
    [build_args]=""
    [env_to_args]="DOCKERHUB_USERNAME"
)

declare -A IMAGE_MAKE=(
    [name]="make"
    [platforms]="arm64,amd64"
    [dockerfile]="dev/docker/make/Dockerfile"
    [context]="dev/docker/make"
    [depends_on]="bash"
    [build_args]=""
    [env_to_args]="DOCKERHUB_USERNAME"
)

declare -A IMAGE_OPENTOFU=(
    [name]="opentofu"
    [platforms]="arm64,amd64"
    [dockerfile]="dev/docker/opentofu/Dockerfile"
    [context]="dev/docker/opentofu"
    [depends_on]="bash"
    [build_args]="OPENTOFU_RELEASE=${OPENTOFU_RELEASE:-1.10.0}"
    [env_to_args]="DOCKERHUB_USERNAME BASH_CHECKSUM"
)

declare -A IMAGE_NODE_SEMANTIC_RELEASE=(
    [name]="node-semantic-release"
    [platforms]="arm64,amd64"
    [dockerfile]="dev/docker/node-semantic-release/Dockerfile"
    [context]="dev/docker/node-semantic-release"
    [depends_on]="bash"
    [build_args]=""
    [env_to_args]="DOCKERHUB_USERNAME BASH_CHECKSUM"
)

declare -A IMAGE_CDK8S=(
    [name]="cdk8s"
    [platforms]="arm64,amd64"
    [dockerfile]="dev/docker/cdk8s/Dockerfile"
    [context]="dev/docker/cdk8s"
    [depends_on]="bash"
    [build_args]=""
    [env_to_args]="DOCKERHUB_USERNAME BASH_CHECKSUM"
)

# Ordine di build delle immagini
BUILD_ORDER=(
    "IMAGE_MAKE"
    "IMAGE_BASH"
    "IMAGE_OPENTOFU"
    "IMAGE_NODE_SEMANTIC_RELEASE"
    "IMAGE_CDK8S"
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
