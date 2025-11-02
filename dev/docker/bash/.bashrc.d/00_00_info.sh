#!/bin/bash

set -a
source /etc/image-info
set +a

# Informazioni minime (no variabili d'ambiente per evitare leak di segreti)
echo "------- INFORMATION --------"
echo "Image: ${IMAGE_FULL_NAME}"
echo "User: $(whoami) ($(id -u)/$(id -g))"
echo "Time: $(date)"
echo "Bash: $BASH_VERSION"
echo "CWD: $(pwd)"
echo "Host: $(hostname)"
echo "OS: $(uname -srm)"
echo "params: $@"
echo "----------------------------"