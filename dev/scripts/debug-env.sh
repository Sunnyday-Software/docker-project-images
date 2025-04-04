#!/bin/bash

source .env

# Stampa informazioni sull'ambiente
echo "---- DEBUG INFORMATION -----"
echo "Informazioni sull'ambiente: "
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
echo "file .env"
cat  ./.env
echo "----------------------------"