#!/bin/bash

set -a
source /etc/image-info
set +a

# Controlla se gli script .bashrc.d sono già stati caricati
if [ "${__BASHRC_LOADED:-}" != "true" ]; then
    export __BASHRC_LOADED="true"

  # Carica una sola volta tutti gli script in ~/.bashrc.d/
  for file in ~/.bashrc.d/*.sh; do
      # Se il file è quello attuale ("load.sh"), saltalo per evitare auto-ricorsione
      if [[ "$(realpath "$file")" == "$(realpath "${BASH_SOURCE[0]}")" ]]; then
          continue
      fi

      # Normalizza CRLF -> LF per evitare syntax error in bash
      if command -v dos2unix >/dev/null 2>&1; then
          echo "normalizing file: $file"
          dos2unix "$file" >/dev/null 2>&1 || true
      else
          sed -i 's/\r$//' "$file" 2>/dev/null || true
      fi
      chmod +x "$file" 2>/dev/null || true

      [ -f "$file" ] && . "$file"
  done


  echo "✅ All .bashrc.d scripts loaded successfully"
else
  echo "ℹ️  .bashrc.d scripts already loaded"
fi

# Informazioni minime (no variabili d'ambiente per evitare leak di segreti)
echo "------- INFORMATION --------"
echo "Image: ${IMAGE_FULL_NAME}"
echo "User: $(whoami) ($(id -u)/$(id -g))"
echo "Time: $(date)"
echo "Bash: $BASH_VERSION"
echo "CWD: $(pwd)"
echo "Host: $(hostname)"
echo "OS: $(uname -srm)"
echo "----------------------------"