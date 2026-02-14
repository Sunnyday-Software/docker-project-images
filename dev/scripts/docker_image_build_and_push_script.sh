#!/usr/bin/env bash

# Parse command line arguments
DEBUG=false
NOPUSH=false
CMD_PRN=false
AMD64_PLATFORM=true
ARM64_PLATFORM=true
STOP_AFTER_IMAGE=""
STOP_AFTER_FIRST_PLATFORM=false

# Parse args (supporta opzioni con valore)
while [ $# -gt 0 ]; do
    case "$1" in
        --debug)
            DEBUG=true
            NOPUSH=true
            shift
            ;;
        --no-push)
            NOPUSH=true
            shift
            ;;
        --cmd-prn)
            CMD_PRN=true
            shift
            ;;
        --amd64-only)
            ARM64_PLATFORM=false
            shift
            ;;
        --arm64-only)
            AMD64_PLATFORM=false
            shift
            ;;
        --stop-after)
            shift
            STOP_AFTER_IMAGE="${1:-}"
            if [ -z "$STOP_AFTER_IMAGE" ]; then
                echo "❌ --stop-after richiede un nome immagine (es: --stop-after bash)"
                exit 1
            fi
            shift
            ;;
        --stop-after-first-platform)
            STOP_AFTER_FIRST_PLATFORM=true
            shift
            ;;
        *)
            # Unknown option, keep it for other processing
            shift
            ;;
    esac
done

log() {
    if [ "$CMD_PRN" != true ]; then
        echo "$*"
    fi
}

load_file_with_export() {
    local env_file="$1"

    if [ -f "$env_file" ]; then
        local filename=$(basename "$env_file")
        log "Loading $filename..."

        # Abilita export automatico
        set -a
        source "$env_file"
        # Disabilita export automatico
        set +a

        return 0
    else
        log "File not found: $env_file"
        return 1
    fi
}

# Source
source "$(dirname "$0")/error_handler.sh"
load_file_with_export "$(dirname "$0")/../../.env"
load_file_with_export "$(dirname "$0")/../docker/versions.properties"

source "$(dirname "$0")/../../build_config.sh"

echo "===================="
env
echo "===================="

set -e


#log or execute
lx() {
  if [ "$CMD_PRN" = true ]; then
    echo "$*"
    return 0
  else
    log_and_execute "$@"
    return $?
  fi
}


log "Script di build delle immagini"
log "$(dirname "$0")"
log ""
log env
log "------------------------------"

# Costruisci la lista delle piattaforme basata sui flag
ENABLED_PLATFORMS=()
if [ "$ARM64_PLATFORM" = true ]; then
    ENABLED_PLATFORMS+=("arm64")
fi
if [ "$AMD64_PLATFORM" = true ]; then
    ENABLED_PLATFORMS+=("amd64")
fi


# Se nessuna piattaforma è abilitata, usa il default
if [ ${#ENABLED_PLATFORMS[@]} -eq 0 ]; then
    ENABLED_PLATFORMS=("arm64" "amd64")
fi

# Costruisci la stringa PLATFORMS
PLATFORMS=$(IFS=','; echo "${ENABLED_PLATFORMS[*]}")
IFS=',' read -ra PLATFORM_LIST <<< "$PLATFORMS"

log "🚀 Avvio build delle immagini Docker"
log "📋 Ordine di build: ${BUILD_ORDER[*]}"
log "🏗️  Piattaforme richieste: ${PLATFORMS}"
if [ "$NOPUSH" = true ]; then
    log "⚠️  Modalità --no-push attiva: le immagini non verranno pushate"
fi

# Funzione per verificare se un'immagine esiste localmente
image_exists_locally() {
    if [ "$DEBUG" = true ]; then
        log "⚠️  Pull fallito per DEBUG mode"
        return 1
    fi
    if [ "$CMD_PRN" = true ]; then
      return 1
    else
      local image_tag="$1"
      if docker image inspect "$image_tag" &> /dev/null; then
          return 0  # True
      else
          return 1  # False
      fi
    fi
}

# Funzione per tentare il pull di un'immagine
try_pull_image() {
    if [ "$DEBUG" = true ]; then
        log "⚠️  Pull fallito per DEBUG mode"
        return 1
    fi

    local image_tag="$1"
    log "🔄 Tentativo di pull dell'immagine: $image_tag"

    if [ "$CMD_PRN" = true ]; then
      echo "docker pull -q \"$image_tag\""
      return 1
    else
      if docker pull -q "$image_tag" 2>/dev/null; then
          log "✅ Pull completato con successo per: $image_tag"
          return 0
      else
          log "⚠️  Pull fallito per: $image_tag (l'immagine potrebbe non esistere nel registry)"
          return 1
      fi
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
    local env_to_args="${image_data[env_to_args]:-}"

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
    if [ "$DEBUG" = true ]; then
        image_tag="localbuild"
    fi
    local full_tag="${full_image_name}:${image_tag}"

    local latest_tag="${full_image_name}:latest-${platform_tag}"

    log "🔨 Building: $full_tag"
    log "   📁 Context: $context"
    log "   📄 Dockerfile: $dockerfile"
    log "   🏗️  Platform: $platform"

    # Verifica se l'immagine esiste già localmente, altrimenti tenta il pull
    local image_available=false
    if image_exists_locally "$full_tag"; then
        log "✅ Immagine già presente localmente: $full_tag"
        image_available=true
    else
        log "🔍 Immagine non trovata localmente, tentativo di pull..."
        if try_pull_image "$full_tag"; then
            log "✅ Immagine ottenuta tramite pull: $full_tag"
            image_available=true
        else
            log "⚠️  Pull fallito, procedo con il build"
            try_pull_image "${full_image_name}:latest"
            image_available=false
        fi
    fi

    # Se l'immagine è già disponibile, salta il build
    if [ ! "$image_available" = true ]; then

      log "🔨 Procedo con il build dell'immagine: $full_tag"
      local build_cmd="docker --debug build --no-cache "
      build_cmd+=" --platform $platform"
      build_cmd+=" --provenance=false"
      build_cmd+=" --sbom=false"
      build_cmd+=" -f $dockerfile"
      build_cmd+=" -t $full_tag"
      build_cmd+=" --build-arg IMAGE_FULL_NAME=\"$full_tag\" "
      build_cmd+=" --build-arg PLATFORM_TAG=$platform_tag"
      if [ "$DEBUG" = true ]; then
        build_cmd+=" --build-arg BASE_IMAGE=\"${DOCKERHUB_USERNAME}/bash:localbuild\" "
      fi


      # Aggiungi build args se presenti
      if [ -n "$build_args" ]; then
          IFS=' ' read -ra ARGS <<< "$build_args"
          for arg in "${ARGS[@]}"; do
              build_cmd+=" --build-arg $arg"
          done
      fi

      # Aggiungi env_to_args se presenti
      if [ -n "$env_to_args" ]; then
          IFS=' ' read -ra ENV_VARS <<< "$env_to_args"
          for env_var in "${ENV_VARS[@]}"; do
              if [ -n "${!env_var:-}" ]; then
                  value="${!env_var}"
                  escaped_value="${value//\"/\\\"}"  # Escape delle virgolette
                  build_cmd+=" --build-arg $env_var=\"$escaped_value\""
              else
                  log "❌ Variabile ambientale richiesta non trovata: $env_var"
                  return 1
              fi
          done
      fi

      build_cmd+=" $context"

      log "   ⚡ Comando: $build_cmd"
      if [ "$CMD_PRN" = true ]; then
        echo "$build_cmd"
      else
        eval "$build_cmd"
      fi
    fi

    # In DEBUG mode: nessun tag aggiuntivo (né latest-*, né checksum-arch)
    if [ "$DEBUG" = true ]; then
        return 0
    fi

    lx docker tag $full_tag $latest_tag

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

    local latest_tag="${full_image_name}:latest-${platform_tag}"

    log "📤 Pushing: $full_tag"
    lx docker push -q "$full_tag"
    lx docker push -q "$latest_tag"
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

    log ""
    log "🏷️  === CREAZIONE MANIFESTI PER: $image_name ==="

    if is_multiplatform "$image_ref"; then
        log "🏗️  Immagine multipiattaforma: $image_name"
        log "📦 Creazione manifesti per le piattaforme abilitate: ${PLATFORMS}..."

        # Costruisci la lista delle immagini per il manifesto
        local manifest_images=()
        for platform in "${ENABLED_PLATFORMS[@]}"; do
            manifest_images+=("${full_image_name}:${expected_checksum}-${platform}")
        done

        # Helper: crea (o amenda) un manifest in modo compatibile
        create_or_amend_manifest() {
            local target_tag="$1"; shift

            local amend_flag=""
            if docker manifest inspect "$target_tag" >/dev/null 2>&1; then
                amend_flag="--amend"
            fi

            # Best effort: se non esiste non è un errore “vero”
            docker manifest rm "$target_tag" >/dev/null 2>&1 || true

            lx docker manifest create $amend_flag "$target_tag" "$@"
            lx docker manifest push "$target_tag"
        }

        # Crea manifesto per checksum tag
        log "📋 ${full_image_name}:${expected_checksum} -> ${manifest_images[*]}"
        create_or_amend_manifest "${full_image_name}:${expected_checksum}" "${manifest_images[@]}"

        # Crea manifesto per version tag
        log "📋 ${full_image_name}:${expected_version} -> ${manifest_images[*]}"
        create_or_amend_manifest "${full_image_name}:${expected_version}" "${manifest_images[@]}"

        # Crea manifesto per latest tag
        log "📋 ${full_image_name}:latest -> ${manifest_images[*]}"
        create_or_amend_manifest "${full_image_name}:latest" "${manifest_images[@]}"

    else
        log "🔧 Immagine single-platform: $image_name"
        log "🏷️  Tagging solo con latest (assumendo amd64)..."

        # Per immagini single-platform, tagga solo l'immagine esistente come latest
        single_platform_tag="${full_image_name}:${expected_checksum}-amd64"

        log "🏷️  Tagging ${single_platform_tag} come latest"
        lx docker tag "$single_platform_tag" "${full_image_name}:latest"
        lx docker push "${full_image_name}:latest"

        # Tagga anche con version
        log "🏷️  Tagging ${single_platform_tag} come ${expected_version}"
        lx docker tag "$single_platform_tag" "${full_image_name}:${expected_version}"
        lx docker push "${full_image_name}:${expected_version}"
    fi

    log "✅ === MANIFESTI COMPLETATI PER: $image_name ==="
}

# Funzione principale di build
main() {
    # Verifica delle dipendenze Docker
    if ! command -v docker &> /dev/null; then
        log "❌ Docker non trovato!"
        exit 1
    fi

    # Login Docker Hub se necessario
    if [ -n "${DOCKERHUB_TOKEN:-}" ] && [ -n "${DOCKERHUB_USERNAME:-}" ]; then
        log "🔐 Login Docker Hub..."
        if [ "$CMD_PRN" = true ]; then
          echo "echo \"\$DOCKERHUB_TOKEN\" | docker login -u \"\$DOCKERHUB_USERNAME\" --password-stdin"
        else
          echo "$DOCKERHUB_TOKEN" | docker login -u "$DOCKERHUB_USERNAME" --password-stdin
        fi
    fi

    # Ciclo attraverso le immagini nell'ordine specificato
    for image_ref in "${BUILD_ORDER[@]}"; do
        local -n image_data=$image_ref
        local image_name="${image_data[name]}"

        log ""
        log "🏗️  === BUILDING IMAGE: $image_name ==="

        # Verifica dipendenze
        local dependencies=$(get_dependencies "$image_ref")
        if [ -n "$dependencies" ]; then
            log "📦 Dipendenze: $dependencies"
            # Qui potresti aggiungere controlli per verificare che le dipendenze siano già state buildinate
        fi

        # Build per ogni piattaforma supportata
        for platform_full in "${PLATFORM_LIST[@]}"; do
            local platform="linux/$platform_full"

            if supports_platform "$image_ref" "$platform_full"; then
                log "✅ Piattaforma $platform_full supportata per $image_name"

                # Build
                if build_single_image "$image_ref" "$platform"; then
                    log "✅ Build completata per $image_name su $platform_full"

                    # Push immediato dopo il build (solo se non è attivo --nopush)
                    if [ "$NOPUSH" = true ]; then
                        log "⏭️  Push saltato per $image_name su $platform_full (--nopush attivo)"
                    else
                        if push_single_image "$image_ref" "$platform"; then
                            log "✅ Push completato per $image_name su $platform_full"
                        else
                            log "❌ Errore durante il push di $image_name su $platform_full"
                            exit 1
                        fi
                    fi

                    # 🛑 opzionale: fermati subito dopo la prima piattaforma
                    if [ "$STOP_AFTER_FIRST_PLATFORM" = true ] && [ -n "$STOP_AFTER_IMAGE" ] && [ "$image_name" = "$STOP_AFTER_IMAGE" ]; then
                        log "🛑 Stop richiesto (--stop-after-first-platform) dopo $image_name su $platform_full"
                        return 0
                    fi
                else
                    log "❌ Errore durante il build di $image_name su $platform_full"
                    exit 1
                fi
            else
                log "⏭️  Piattaforma $platform_full non supportata per $image_name, salto"
            fi
        done

        # Crea manifesti dopo che tutte le piattaforme sono state processate (solo se non è attivo --nopush)
        if [ "$NOPUSH" = true ]; then
            log "⏭️  Creazione manifesti saltata per $image_name (--nopush attivo)"
        elif [ "$AMD64_PLATFORM" = true ] && [ "$ARM64_PLATFORM" = true ]; then
            if create_manifests "$image_ref"; then
                log "✅ Manifesti creati con successo per $image_name"
            else
                log "❌ Errore durante la creazione dei manifesti per $image_name"
                exit 1
            fi
        else
            log "⏭️  Creazione manifesti saltata per $image_name (non tutte le piattaforme sono abilitate)"
        fi

        log "✅ === COMPLETATA IMAGE: $image_name ==="

        # 🛑 Stop dopo aver completato l’immagine richiesta (tutte le piattaforme)
        if [ -n "$STOP_AFTER_IMAGE" ] && [ "$image_name" = "$STOP_AFTER_IMAGE" ]; then
            log "🛑 Stop richiesto: fermo il ciclo dopo l’immagine '$STOP_AFTER_IMAGE'"
            break
        fi
    done

    log ""
    if [ "$NOPUSH" = true ]; then
        log "🎉 Build di tutte le immagini completato! (Push saltato per --no-push/--debug)"
    else
        log "🎉 Build e push di tutte le immagini completati!"
    fi
}

# Esegui solo se script chiamato direttamente
if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
    main "$@"
fi
