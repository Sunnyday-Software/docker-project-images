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

      # Normalizza CRLF -> LF per evitare syntax error in bash
      if command -v dos2unix >/dev/null 2>&1; then
          echo "normalizing file: $file"
          dos2unix "$file" >/dev/null 2>&1 || true
      else
          sed -i 's/\r$//' "$file" 2>/dev/null || true
      fi
      chmod +x "$file" 2>/dev/null || true

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
