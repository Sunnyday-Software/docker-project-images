#!/usr/bin/env bash

source "$(dirname "$0")/../../build_config.sh"

# Ciclo attraverso le immagini nell'ordine specificato
for image_ref in "${BUILD_ORDER[@]}"; do
    image_data=$image_ref
    image_name="${image_data[name]}"
    deps_dir="$context/dependencies"
    # Rimuovi e ricrea la cartella dependencies
    if [ -d "$deps_dir" ]; then
        rm -rf "$deps_dir"
    fi
    mkdir -p "$deps_dir"

done