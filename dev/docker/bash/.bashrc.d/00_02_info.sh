#!/bin/bash

source "/opt/bash_libs/import_libs.sh"
BRC_INFO_SH_S_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
lib_guard "BRC_INFO_SH_S_DIR" || { return 0 2>/dev/null || exit 0; }

set -a
source /etc/image-info
set +a

# Informazioni minime (no variabili d'ambiente per evitare leak di segreti)
log_debug "------- INFORMATION --------"
log_debug "Image: ${IMAGE_FULL_NAME}"
log_debug "User: $(whoami) ($(id -u)/$(id -g))"
log_debug "Time: $(date)"
log_debug "Bash: $BASH_VERSION"
log_debug "CWD: $(pwd)"
log_debug "Host: $(hostname)"
log_debug "OS: $(uname -srm)"
log_debug "params: $@"
log_debug "----------------------------"
