#!/usr/bin/env bash

IMPORT_LIBS_SH_S_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
export BASH_LIBS="${IMPORT_LIBS_SH_S_DIR}"

source "$BASH_LIBS/libs.sh"
lib_guard "IMPORT_LIBS_SH" || { return 0 2>/dev/null || exit 0; }

source "$BASH_LIBS/emoji.sh"
source "$BASH_LIBS/env.sh"
source "$BASH_LIBS/logging.sh"
source "$BASH_LIBS/utils.sh"


log_enable_debug "${DPM_DEBUG:-0}"
