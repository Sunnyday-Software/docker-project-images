#!/bin/bash

source "/opt/bash_libs/import_libs.sh"
BRC_ROOT_LOAD_SH_S_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
lib_guard "BRC_ROOT_LOAD_SH_S_DIR" || { return 0 2>/dev/null || exit 0; }


# Carica una sola volta tutti gli script in ~/.bashrc.d/
for file in ~/.bashrc.d/*.sh; do
  # Se il file è quello attuale ("load.sh"), saltalo per evitare auto-ricorsione
  if [[ "$(realpath "$file")" == "$(realpath "${BASH_SOURCE[0]}")" ]]; then
    continue
  fi
  if [ -f "$file" ]; then
    log_debug "📚 ...loading library $file"
    . "$file"
  fi
done

log_debug "✅ All .bashrc.d scripts loaded successfully"

