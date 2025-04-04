#!/usr/bin/dumb-init /usr/bin/bash

# https://github.com/Yelp/dumb-init

set -e

# Prevent core dumps
ulimit -c 0

[ -f dev/scripts/env.sh ] && . dev/scripts/env.sh

# Stampa informazioni sull'ambiente
echo "--- MAKE CONTAINER ----"
echo "Informazioni sull'ambiente:"
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
echo "Comando eseguito: $@"
echo "----------------------------"



exec "$@"

