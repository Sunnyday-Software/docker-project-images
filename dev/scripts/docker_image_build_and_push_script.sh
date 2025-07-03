#!/bin/bash

# Funzione per caricare un file con source se esiste
load_file_if_exists() {
    local file_path="$1"

    if [ -f "$file_path" ]; then
        local filename=$(basename "$file_path")
        echo "Loading $filename..."
        source "$file_path"
        return 0
    else
        echo "File not found: $file_path"
        return 1
    fi
}

load_file_with_export() {
    local env_file="$1"

    if [ -f "$env_file" ]; then
        local filename=$(basename "$env_file")
        echo "Loading $filename..."

        # Abilita export automatico
        set -a
        source "$env_file"
        # Disabilita export automatico
        set +a

        return 0
    else
        echo "File not found: $env_file"
        return 1
    fi
}


# Source the error handler and configuration
load_file_if_exists "$(dirname "$0")/error_handler.sh"
load_file_if_exists "$(dirname "$0")/../../build_config.sh"
load_file_with_export "$(dirname "$0")/../../.env"
load_file_with_export "$(dirname "$0")/../docker/versions.properties"

echo "=== Contenuto del file .env ==="
if [ -f "$(dirname "$0")/../../.env" ]; then
    cat "$(dirname "$0")/../../.env"
else
    echo "File .env non trovato!"
fi
echo "==============================="


set -e

echo "Script di build delle immagini"
echo "$(dirname "$0")"
echo ""
env
echo "------------------------------"

# Default platforms se non specificato
PLATFORMS="${DOCKER_PLATFORMS:-amd64,arm64}"
IFS=',' read -ra PLATFORM_LIST <<< "$PLATFORMS"

echo "🚀 Avvio build delle immagini Docker"
echo "📋 Ordine di build: ${BUILD_ORDER[*]}"
echo "🏗️  Piattaforme richieste: ${PLATFORMS}"

# Funzione per verificare se un'immagine esiste localmente
image_exists_locally() {
    local image_tag="$1"
    docker image inspect "$image_tag" &> /dev/null
}

# Funzione per tentare il pull di un'immagine
try_pull_image() {
    local image_tag="$1"
    echo "🔄 Tentativo di pull dell'immagine: $image_tag"

    if docker pull "$image_tag" 2>/dev/null; then
        echo "✅ Pull completato con successo per: $image_tag"
        return 0
    else
        echo "⚠️  Pull fallito per: $image_tag (l'immagine potrebbe non esistere nel registry)"
        return 1
    fi
}

# Funzione per fare il build di una singola immagine su una piattaforma
build_single_image() {
    local image_ref="$1"
    local platform="$2"
    local -n image_data=$image_ref

    local image_name="${image_data[name]}"
    local dockerfile="${image_data[dockerfile]}"
    local context="${image_data[context]}"
    local build_args="${image_data[build_args]:-}"

    # Calcola il checksum per il versioning
    local normalized_name=$(echo "$image_name" | tr '[:lower:]' '[:upper:]' | sed 's/[^[:alnum:]]/_/g')
    local checksum_var="${normalized_name}_CHECKSUM"
    local expected_checksum=${!checksum_var}

    if [ -z "$expected_checksum" ]; then
        echo "❌ Checksum non trovato per $image_name (variabile: $checksum_var)"
        return 1
    fi

    local full_image_name="${DOCKERHUB_USERNAME}/${image_name}"
    local platform_tag=$(echo "$platform" | sed 's/linux\///')
    local image_tag="${expected_checksum}-${platform_tag}"
    local full_tag="${full_image_name}:${image_tag}"

    echo "🔨 Building: $full_tag"
    echo "   📁 Context: $context"
    echo "   📄 Dockerfile: $dockerfile"
    echo "   🏗️  Platform: $platform"

    # Verifica se l'immagine esiste già localmente, altrimenti tenta il pull
    local image_available=false
    if image_exists_locally "$full_tag"; then
        echo "✅ Immagine già presente localmente: $full_tag"
        image_available=true
    else
        echo "🔍 Immagine non trovata localmente, tentativo di pull..."
        if try_pull_image "$full_tag"; then
            echo "✅ Immagine ottenuta tramite pull: $full_tag"
            image_available=true
        else
            echo "⚠️  Pull fallito, procedo con il build"
            image_available=false
        fi
    fi

    # Se l'immagine è già disponibile, salta il build
    if [ "$image_available" = true ]; then
        echo "⏭️  Immagine già presente, salto il build: $full_tag"
        return 0
    fi

    # Costruisci il comando docker build
    echo "🔨 Procedo con il build dell'immagine: $full_tag"
    local build_cmd="docker build"
    build_cmd+=" --platform $platform"
    build_cmd+=" -f $dockerfile"
    build_cmd+=" -t $full_tag"

    # Aggiungi build args se presenti
    if [ -n "$build_args" ]; then
        IFS=' ' read -ra ARGS <<< "$build_args"
        for arg in "${ARGS[@]}"; do
            build_cmd+=" --build-arg $arg"
        done
    fi

    build_cmd+=" $context"

    echo "   ⚡ Comando: $build_cmd"
    eval "$build_cmd"

    return 0
}

# Funzione per fare il push di un'immagine
push_single_image() {
    local image_ref="$1"
    local platform="$2"
    local -n image_data=$image_ref

    local image_name="${image_data[name]}"
    local normalized_name=$(echo "$image_name" | tr '[:lower:]' '[:upper:]' | sed 's/[^[:alnum:]]/_/g')
    local checksum_var="${normalized_name}_CHECKSUM"
    local expected_checksum=${!checksum_var}

    local full_image_name="${DOCKERHUB_USERNAME}/${image_name}"
    local platform_tag=$(echo "$platform" | sed 's/linux\///')
    local image_tag="${expected_checksum}-${platform_tag}"
    local full_tag="${full_image_name}:${image_tag}"

    echo "📤 Pushing: $full_tag"
    docker push "$full_tag"
}

# Funzione per verificare se un'immagine è multipiattaforma
is_multiplatform() {
    local image_ref="$1"
    local -n image_data=$image_ref
    local platforms="${image_data[platforms]}"
    # È multipiattaforma se contiene sia amd64 che arm64
    [[ "$platforms" == *"amd64"* && "$platforms" == *"arm64"* ]]
}

# Funzione per creare i manifesti multipiattaforma
create_manifests() {
    local image_ref="$1"
    local -n image_data=$image_ref

    local image_name="${image_data[name]}"
    local normalized_name=$(echo "$image_name" | tr '[:lower:]' '[:upper:]' | sed 's/[^[:alnum:]]/_/g')
    local checksum_var="${normalized_name}_CHECKSUM"
    local expected_checksum=${!checksum_var}
    local version_var="${normalized_name}_VERSION"
    local expected_version="v-${!version_var}"

    local full_image_name="${DOCKERHUB_USERNAME}/${image_name}"

    echo ""
    echo "🏷️  === CREAZIONE MANIFESTI PER: $image_name ==="

    if is_multiplatform "$image_ref"; then
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

    echo "✅ === MANIFESTI COMPLETATI PER: $image_name ==="
}

# Funzione principale di build
main() {
    # Verifica delle dipendenze Docker
    if ! command -v docker &> /dev/null; then
        echo "❌ Docker non trovato!"
        exit 1
    fi

    # Login Docker Hub se necessario
    if [ -n "${DOCKERHUB_TOKEN:-}" ] && [ -n "${DOCKERHUB_USERNAME:-}" ]; then
        echo "🔐 Login Docker Hub..."
        echo "$DOCKERHUB_TOKEN" | docker login -u "$DOCKERHUB_USERNAME" --password-stdin
    fi

    # Ciclo attraverso le immagini nell'ordine specificato
    for image_ref in "${BUILD_ORDER[@]}"; do
        local -n image_data=$image_ref
        local image_name="${image_data[name]}"

        echo ""
        echo "🏗️  === BUILDING IMAGE: $image_name ==="

        # Verifica dipendenze
        local dependencies=$(get_dependencies "$image_ref")
        if [ -n "$dependencies" ]; then
            echo "📦 Dipendenze: $dependencies"
            # Qui potresti aggiungere controlli per verificare che le dipendenze siano già state buildinate
        fi

        # Build per ogni piattaforma supportata
        for platform_full in "${PLATFORM_LIST[@]}"; do
            local platform="linux/$platform_full"

            if supports_platform "$image_ref" "$platform_full"; then
                echo "✅ Piattaforma $platform_full supportata per $image_name"

                # Build
                if build_single_image "$image_ref" "$platform"; then
                    echo "✅ Build completata per $image_name su $platform_full"

                    # Push immediato dopo il build
                    if push_single_image "$image_ref" "$platform"; then
                        echo "✅ Push completato per $image_name su $platform_full"
                    else
                        echo "❌ Errore durante il push di $image_name su $platform_full"
                        exit 1
                    fi
                else
                    echo "❌ Errore durante il build di $image_name su $platform_full"
                    exit 1
                fi
            else
                echo "⏭️  Piattaforma $platform_full non supportata per $image_name, salto"
            fi
        done

        # Crea manifesti dopo che tutte le piattaforme sono state processate
        if create_manifests "$image_ref"; then
            echo "✅ Manifesti creati con successo per $image_name"
        else
            echo "❌ Errore durante la creazione dei manifesti per $image_name"
            exit 1
        fi

        echo "✅ === COMPLETATA IMAGE: $image_name ==="
    done

    echo ""
    echo "🎉 Build e push di tutte le immagini completati!"
}

# Esegui solo se script chiamato direttamente
if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
    main "$@"
fi
