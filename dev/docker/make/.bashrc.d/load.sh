#!/bin/bash

set -a
source /etc/image-info
set +a

echo "Running load.sh"

# Controlla se gli script .bashrc.d sono già stati caricati
if [ "${__BASHRC_LOADED:-}" != "true" ]; then
    export __BASHRC_LOADED="true"

  # Carica una sola volta tutti gli script in ~/.bashrc.d/
  for file in ~/.bashrc.d/*.sh; do
      # Se il file è quello attuale ("load.sh"), saltalo per evitare auto-ricorsione
      if [[ "$(realpath "$file")" == "$(realpath "${BASH_SOURCE[0]}")" ]]; then
          continue
      fi

      echo "🔄 Processing file: $file"

      if [ -f "$file" ]; then
          echo "🚀 Sourcing: $file"

          # Disabilita temporaneamente set -e per questo script specifico
          set +e
          source "$file"
          local_exit_code=$?
          set -e
          if [ $local_exit_code -ne 0 ]; then
              echo "⚠️  Warning: $file exited with code $local_exit_code, but continuing..."
          else
              echo "✅ Successfully sourced: $file"
          fi

      fi
  done

  echo "✅ All .bashrc.d scripts loaded successfully"
else
  echo "ℹ️  .bashrc.d scripts already loaded"
fi
