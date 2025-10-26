#!/bin/bash

set -e


# Funzione per caricare file .env in modo sicuro
function load_dotenv() {
    local env_file="${1:-/workdir/.env}"

    if [ -f "$env_file" ]; then
        echo "🔧 Caricando variabili d'ambiente da: $env_file"

        # Usa set -a per esportare automaticamente tutte le variabili
        set -a
        # Source del file con gestione errori
        source "$env_file" 2>/dev/null || {
            echo "⚠️  Errore nel caricamento di $env_file, provo con parsing alternativo..."

            # Metodo alternativo: parsing linea per linea
            while IFS='=' read -r key value; do
                # Salta righe vuote e commenti
                [[ $key =~ ^[[:space:]]*$ ]] && continue
                [[ $key =~ ^[[:space:]]*# ]] && continue

                # Rimuovi spazi bianchi e quotes
                key=$(echo "$key" | xargs)
                value=$(echo "$value" | xargs)

                # Rimuovi eventuali quotes dal valore
                value="${value%\"}"
                value="${value#\"}"
                value="${value%\'}"
                value="${value#\'}"

                # Esporta la variabile
                export "$key"="$value"
                echo "  ✓ $key=$value"
            done < "$env_file"
        }
        set +a
        echo "✅ Variabili d'ambiente caricate da $env_file"
    else
        echo "⚠️  File $env_file non trovato"
    fi
}


