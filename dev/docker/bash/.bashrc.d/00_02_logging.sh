#!/usr/bin/env bash

: "${DPM_DEBUG:=0}"

is_log_enabled_debug() {
  case "${DPM_DEBUG}" in
  1|true|TRUE|True|yes|YES|on|ON) return 0 ;;
  *) return 1 ;;
  esac
}

: "${LOG_INDENT:=0}"
: "${LOG_WIDTH:=80}"


# Stampa riga di log con indentazione
internal_log() {
  local lvl="$1"; shift
  local indent=""
  (( LOG_INDENT > 0 )) && indent="$(printf '%*s' $((LOG_INDENT*2)) '')"
  printf '[%s] %s%s\n' "$lvl" "$indent" "$*" >&2
}

log_info()  { internal_log INFO  "$@"; }
log_warn()  { internal_log WARN  "$@"; }
log_err()   { internal_log ERROR "$@"; }
log_debug() {
  if is_log_enabled_debug; then
    internal_log DEBUG "$@";
  fi
}
log_debug_env_var() {
  local var="$1"
  is_log_enabled_debug || return 0
  [ -z "$var" ] && return 0
  # espansione indiretta: prende anche variabili non esportate
  local val="${!var}"
  log_debug "${var}=${val}"
}

# Titolo di sezione: incrementa indentazione e stampa
# Esempio: with_section "Build" && ... ; end_section
log_section() {
  local title="$*"
  local prefix="$(printf '%*s' $((LOG_INDENT*2)) '')"
  local head="${prefix}${title} "
  local n=${#head}
  local max=$LOG_WIDTH
  (( n < max )) && head+=$(printf '%*s' $((max-n)) '' | tr ' ' '-')
  printf '[INFO] %s\n' "$head" >&2
  ((LOG_INDENT++))
}

# Sezione solo debug: non stampa nulla se il debug è disattivato
log_debug_section() {
  is_log_enabled_debug || { ((LOG_INDENT++)); return 0; }
  local title="$*"
  local prefix="$(printf '%*s' $((LOG_INDENT*2)) '')"
  local head="${prefix}${title} "
  local n=${#head}
  local max=$LOG_WIDTH
  (( n < max )) && head+=$(printf '%*s' $((max-n)) '' | tr ' ' '-')
  printf '[DEBUG] %s\n' "$head" >&2
  ((LOG_INDENT++))
}

# Variante che non incrementa indentazione (solo stampa titolo)
log_flat_section() {
  local title="$*"
  local prefix="$(printf '%*s' $((LOG_INDENT*2)) '')"
  local head="${prefix}${title} "
  local n=${#head}
  local max=$LOG_WIDTH
  (( n < max )) && head+=$(printf '%*s' $((max-n)) '' | tr ' ' '-')
  printf '\n'  >&2
}

# Chiude una sezione (decrementa indentazione)
log_end_section() {
  (( LOG_INDENT>0 )) && ((LOG_INDENT--))
}

