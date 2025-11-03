#!/bin/bash

set -a
source /etc/image-info
set +a

# Controlla se gli script .bashrc.d sono già stati caricati
if [ "${__BASHRC_ROOT_LOADED:-}" != "true" ]; then
    export __BASHRC_ROOT_LOADED="true"

  # Carica una sola volta tutti gli script in ~/.bashrc.d/
  for file in ~/.bashrc.d/*.sh; do
      # Se il file è quello attuale ("load.sh"), saltalo per evitare auto-ricorsione
      if [[ "$(realpath "$file")" == "$(realpath "${BASH_SOURCE[0]}")" ]]; then
          continue
      fi
      if [ -f "$file" ]; then
          echo "...loading $file"
          . "$file"
      fi
  done

    echo "✅ All .bashrc.d scripts loaded successfully"
else
    echo "ℹ️  .bashrc.d scripts already loaded"
fi
