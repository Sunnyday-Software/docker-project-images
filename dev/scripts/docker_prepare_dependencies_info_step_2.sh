#!/usr/bin/env bash


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

source "$(dirname "$0")/../../build_config.sh"
load_file_with_export "$(dirname "$0")/../docker/versions.properties"

# Ciclo attraverso le immagini nell'ordine specificato
for image_ref in "${BUILD_ORDER[@]}"; do
    image_data=$image_ref
    image_name="${image_data[name]}"
    deps_dir="$context/dependencies"
    deps_on="${image_data[depends_on]}"
    normalized_name=$(echo "$image_name" | tr '[:lower:]' '[:upper:]' | sed 's/[^[:alnum:]]/_/g')
    checksum_var="${normalized_name}_CHECKSUM"
    checksum_value=${!checksum_var}

    # Process each dependency if deps_on is not empty
    if [ -n "$deps_on" ]; then
        IFS=',' read -ra DEPS <<< "$deps_on"
        for dep in "${DEPS[@]}"; do
            # Remove leading/trailing whitespace
            dep=$(echo "$dep" | xargs)
            if [ -n "$dep" ]; then
                # Write CRC to a file named after the dependency
                echo "$checksum_value" > "$deps_dir/$dep"
                git add "$deps_dir/$dep"
            fi
        done
    fi
    
done