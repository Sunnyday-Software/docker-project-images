#!/bin/bash

# Source the error handler
source "./error_handler.sh"

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
      [ -f "$file" ] && . "$file"
  done

    echo "✅ All .bashrc.d scripts loaded successfully"
else
    echo "ℹ️  .bashrc.d scripts already loaded"
fi

# Stampa informazioni sull'ambiente
echo "------- INFORMATION --------"
echo "Informazioni sull'ambiente: "
echo "Image: ${IMAGE_FULL_NAME}"
echo "----------------------------"
echo "Nome utente corrente: $(whoami), $(id -u)/$(id -g)"
echo "Data e ora attuali: $(date)"
echo "Versione di Bash: $BASH_VERSION"
echo "Directory corrente: $(pwd)"
echo "Hostname della macchina: $(hostname)"
echo "Sistema operativo: $(uname -a)"
echo "Variabili d'ambiente:"
env
echo "----------------------------"