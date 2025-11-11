#!/usr/bin/env bash

# Load library guards and ensure this file is sourced only once.
LOGGING_SH_S_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$LOGGING_SH_S_DIR/libs.sh"
lib_guard "LOGGING_SH" || { return 0 2>/dev/null || exit 0; }

# Robust error handler to avoid quoting/parsing issues on $BASH_COMMAND
debug_error_handler() {
    local rc="$1"
    local src="$2"
    local line="$3"
    local func="$4"
    local cmd="$5"

    echo "[ERR] rc=$rc func=$func src=$src:$line cmd=$cmd" >&2

    echo "call stack:" >&2
    local i=0
    while [[ -n "${FUNCNAME[$i]:-}" ]]; do
        # BASH_SOURCE e BASH_LINENO hanno lo stesso offset
        local fn="${FUNCNAME[$i]}"
        local src="${BASH_SOURCE[$i]:-}"
        local line="${BASH_LINENO[$((i-1))]:-}"   # la linea è sull'elemento precedente
        if [[ $i -eq 0 ]]; then
            echo "  [$i] $fn" >&2
        else
            echo "  [$i] $fn at ${src:-<stdin>}:${line:-?}" >&2
        fi
        ((i++))
    done
}

# Global logging settings with defaults:
# - LOG_INDENT: indentation level (each level = 2 spaces)
# - LOG_WIDTH:  target width for section headers
# - LOG_LEVEL_DEBUG: enable/disable debug logs
: "${LOG_INDENT:=0}"
: "${LOG_WIDTH:=80}"
: "${LOG_LEVEL_DEBUG:=false}"

# Returns 0 if debug logging is enabled, 1 otherwise.
log_is_debug_enabled() {
    case "${LOG_LEVEL_DEBUG}" in
    1|true|TRUE|True|yes|YES|on|ON) return 0 ;;
    *) return 1 ;;
    esac
}

# Enables or disables debug logging based on a truthy/falsy input.
# Accepted truthy values: 1, true, yes, on (case-insensitive).
log_enable_debug() {
    local enabled=$1
    case "${enabled}" in
    1|true|TRUE|True|yes|YES|on|ON)
        LOG_LEVEL_DEBUG=1
        trap 'rc=$?;
        debug_error_handler \
        "$rc" \
        "${BASH_SOURCE[1]:-$BASH_SOURCE}" \
        "${BASH_LINENO[0]:-0}" \
        "${FUNCNAME[1]:-main}" \
        "${BASH_COMMAND}";
        ' ERR
        ;;
    *)
        LOG_LEVEL_DEBUG=0
        trap - EXIT
        ;;
    esac
}

# Print a single log line with current indentation to stderr.
# Usage: internal_log LEVEL message...


internal_log_old() {
    local lvl="$1"; shift
    local indent=""
    (( LOG_INDENT > 0 )) && indent="$(printf '%*s' $((LOG_INDENT*2)) '')"
    printf '[%s] %s%s\n' "$lvl" "$indent" "$*" >&2
}

# restituisce (su stdout) i valori sensibili trovati nell'env
log_build_sensitives() {
    while IFS='=' read -r k v; do
        case "$k" in
        *TOKEN*|*token*|*SECRET*|*secret*|*PASSWORD*|*password*|GH_TOKEN|GIT_HTTP_TOKEN|DPM_GIT_TOKEN_TEMPLATE_*)
            [ -n "$v" ] && printf '%s\n' "$v"
            ;;
        esac
    done < <(env)
}

internal_log() {
    local lvl="$1"; shift
    local indent=""
    (( LOG_INDENT > 0 )) && indent="$(printf '%*s' $((LOG_INDENT*2)) '')"

    # testo originale
    local msg="$*"

    # ricavo i valori sensibili *adesso*
    local sensitive=()
    mapfile -t sensitive < <(log_build_sensitives)

    # li maschero nel messaggio
    local s
    for s in "${sensitive[@]}"; do
        [[ -z "$s" ]] && continue
        msg="${msg//$s/***masked***}"
    done

    printf '[%s] %s%s\n' "$lvl" "$indent" "$msg" >&2
}

# Convenience log functions (all write to stderr).
log_info()  { internal_log INFO  "$@"; }
log_warn()  { internal_log WARN  "$@"; }
log_err()   { internal_log ERROR "$@"; }

# Debug log (prints only when debug is enabled).
log_debug() {
    if log_is_debug_enabled; then
        internal_log DEBUG "$@";
    fi
}

# Debug-print the value of an environment/shell variable by name.
# Uses indirect expansion to also read non-exported variables.
log_debug_env_var() {
    local var="$1"
    log_is_debug_enabled || return 0
    [ -z "$var" ] && return 0
    local val="${!var:-}"
    log_debug "${var}=${val}"
}

# Start a visible section:
# - prints a header line padded with '-' up to LOG_WIDTH
# - increases indentation for subsequent logs
log_section() {
    local title="$*"
    local prefix="$(printf '%*s' $((LOG_INDENT*2)) '')"
    local head="${prefix}${title} "
    local n=${#head}
    local max=$LOG_WIDTH
    (( n < max )) && head+=$(printf '%*s' $((max-n)) '' | tr ' ' '-')
    printf '[INFO] %s\n' "$head" >&2
    ((LOG_INDENT++)) || true
}

# Debug-only section:
# - if debug is OFF, it only increases indentation (silent section)
# - if debug is ON, behaves like log_section with [DEBUG] header
log_debug_section() {
    log_is_debug_enabled || { ((LOG_INDENT++)) || true; return 0; }
    local title="$*"
    local prefix="$(printf '%*s' $((LOG_INDENT*2)) '')"
    local head="${prefix}${title} "
    local n=${#head}
    local max=$LOG_WIDTH
    (( n < max )) && head+=$(printf '%*s' $((max-n)) '' | tr ' ' '-')
    printf '[DEBUG] %s\n' "$head" >&2
    ((LOG_INDENT++)) || true
}

# Flat header variant:
# - prints a blank line to visually separate blocks
# - does NOT change indentation
log_flat_section() {
    local title="$*"
    local prefix="$(printf '%*s' $((LOG_INDENT*2)) '')"
    local head="${prefix}${title} "
    local n=${#head}
    local max=$LOG_WIDTH
    (( n < max )) && head+=$(printf '%*s' $((max-n)) '' | tr ' ' '-')
    printf '\n'  >&2
}

# Close a section by decreasing indentation (no output).
log_end_section() {
    (( LOG_INDENT>0 )) && ((LOG_INDENT--)) || true
}
