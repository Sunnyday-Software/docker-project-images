#!/bin/bash

source "/opt/bash_libs/import_libs.sh"
BRC_INFO_SH_S_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
lib_guard "BRC_INFO_SH_S_DIR" || { return 0 2>/dev/null || exit 0; }

set -a
source /etc/image-info
set +a

# Informazioni minime (no variabili d'ambiente per evitare leak di segreti)
log_info "------- Current runtime --------"
log_info "Image: ${IMAGE_FULL_NAME}"
log_info "User: $(whoami) ($(id -u)/$(id -g))"
log_info "Time: $(date)"
log_info "Bash: $BASH_VERSION"
log_info "CWD: $(pwd)"
log_info "Host: $(hostname)"
log_info "OS: $(uname -srm)"
log_info "params: $*"
log_info "---------------------------------"
