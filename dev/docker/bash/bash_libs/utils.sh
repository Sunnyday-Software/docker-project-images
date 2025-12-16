#!/usr/bin/env bash

UTILS_SH_S_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$UTILS_SH_S_DIR/libs.sh"
lib_guard "UTILS_SH" || { return 0 2>/dev/null || exit 0; }

fixed_signature_args_check() {
    local values=()
    local validators=()
    local sep=0

    # separo valori e validator usando --
    for a in "$@"; do
        if [[ $sep -eq 0 ]]; then
            if [[ "$a" == "--" ]]; then
                sep=1
            else
                values+=("$a")
            fi
        else
            validators+=("$a")
        fi
    done

    local i
    for i in "${!validators[@]}"; do
        local val="${values[i]:-}"
        local spec="${validators[i]}"

        # spec è una stringa tipo: "check_required -name=username -required=1"
        # la spacchiamo in parole
        local parts=()
        # shellcheck disable=SC2206
        parts=($spec)

        local fun="${parts[0]}"
        if ! declare -F "$fun" >/dev/null 2>&1; then
            echo "check_args: validator '$fun' not found" >&2
            return 1
        fi

        # chiamiamo il validatore passando:
        # 1) il valore
        # 2) tutte le opzioni "-k=v" così come sono
        "$fun" "$val" "${parts[@]:1}" || return 1
    done
}

validate_fixed_signed_args() {
    if ! fixed_signature_args_check "$@"; then
        # messaggio principale
        if [[ -n "${CHECK_ARGS_ERROR:-}" ]]; then
            echo "validation error: $CHECK_ARGS_ERROR" >&2
        else
            echo "validation error" >&2
        fi

        echo "Args: "
        local __i=0
        for a in "$@"; do
            echo "  [$__i] ${a:-<empty>}"
            ((__i++))
        done

        # stampa stack delle chiamate
        # FUNCNAME[0] = validate_args
        # FUNCNAME[1] = funzione che ha chiamato validate_args
        # ...
        echo "call stack:" >&2
        local i=0
        while [[ -n "${FUNCNAME[$i]:-}" ]]; do
            # BASH_SOURCE e BASH_LINENO hanno lo stesso offset
            local fn="${FUNCNAME[$i]}"
            local src="${BASH_SOURCE[$i]:-}"
            local line="${BASH_LINENO[$((i-1))]:-}"   # la linea è sull'elemento precedente
            if [[ $i -eq 0 ]]; then
                echo "  [$i] $fn (validator wrapper)" >&2
            else
                echo "  [$i] $fn at ${src:-<stdin>}:${line:-?}" >&2
            fi
            ((i++))
        done

        exit 1
    fi
}


_validator_reset() {
    _v_name="value"
    _v_required=0
    _v_msg=""
}

_validator_parse_common() {
    local opt
    for opt in "$@"; do
        case "$opt" in
        -name=*)     _v_name="${opt#-name=}" ;;
        -required=*) _v_required="${opt#-required=}" ;;
        -msg=*)      _v_msg="${opt#-msg=}" ;;
        *)           _v_other_opts+=("$opt") ;;  # le tengo da parte se servono
        esac
    done
}

# --- validator: required -----------------
check_required() {
    local value="$1"; shift

    local validator_name="check_required"

    _validator_reset
    _v_other_opts=()
    _validator_parse_common "$@"

    if [[ -z "$value" ]]; then
        echo "Validation failure: ${validator_name}(${value})"
        echo "${_v_msg:-$_v_name is required}" >&2
        return 1
    fi
}


# --- validator composto: int con required -----
check_int() {
    local value="$1"; shift

    local validator_name="check_int"

    # reset comuni
    _validator_reset
    _v_other_opts=()

    # parse comuni (-name= -required= -msg=)
    _validator_parse_common "$@"

    local min=""
    local max=""

    # parse comune + specifico
    _validator_parse_common "$@"
    local opt
    for opt in "${_v_other_opts[@]}"; do
        case "$opt" in
        -min=*) min="${opt#-min=}" ;;
        -max=*) max="${opt#-max=}" ;;
        esac
    done


    if [[ -z "$value" ]]; then
        echo "Validation failure: ${validator_name}(${value})"
        echo "${_v_msg:-$_v_name is required}" >&2
        return 1
    fi

    if ! [[ "$value" =~ ^[0-9]+$ ]]; then
        echo "Validation failure: ${validator_name}(${value})"
        echo "${_v_msg:-$_v_name must be an integer}" >&2
        return 1
    fi
    if [[ -n "$min" && "$value" -lt "$min" ]]; then
        echo "Validation failure: ${validator_name}(${value})"
        echo "${_v_msg:-$_v_name must be >= $min}" >&2
        return 1
    fi
    if [[ -n "$max" && "$value" -gt "$max" ]]; then
        echo "Validation failure: ${validator_name}(${value})"
        echo "${_v_msg:-$_v_name must be <= $max}" >&2
        return 1
    fi
}


check_string() {
    local value="$1"; shift

    local validator_name="check_string"

    # reset comuni
    _validator_reset
    _v_other_opts=()

    # parse comuni (-name= -required= -msg=)
    _validator_parse_common "$@"

    # opzioni specifiche
    local min_len=""
    local max_len=""
    local nospace=0
    local uppercase=0
    local lowercase=0

    local opt
    for opt in "${_v_other_opts[@]}"; do
        case "$opt" in
        -minlen=*)   min_len="${opt#-minlen=}" ;;
        -maxlen=*)   max_len="${opt#-maxlen=}" ;;
        -nospace=*)  nospace="${opt#-nospace=}" ;;
        -uppercase=*) uppercase="${opt#-uppercase=}" ;;
        -lowercase=*) lowercase="${opt#-lowercase=}" ;;
        *)
            echo "check_string: unknown option $opt" >&2
            ;;
        esac
    done

    # required?
    if [[ -z "$value" && "$_v_required" -eq 1 ]]; then
        echo "Validation failure: ${validator_name}(${value})"
        echo "${_v_msg:-$_v_name is required}" >&2
        return 1
    fi

    # non required e vuota → ok
    if [[ -z "$value" ]]; then
        return 0
    fi

    local len=${#value}

    if [[ -n "$min_len" && "$len" -lt "$min_len" ]]; then
        echo "Validation failure: ${validator_name}(${value})"
        echo "${_v_msg:-$_v_name must be at least $min_len characters}" >&2
        return 1
    fi

    if [[ -n "$max_len" && "$len" -gt "$max_len" ]]; then
        echo "Validation failure: ${validator_name}(${value})"
        echo "${_v_msg:-$_v_name must be at most $max_len characters}" >&2
        return 1
    fi

    if [[ "$nospace" -eq 1 ]] && [[ "$value" == *" "* ]]; then
        echo "Validation failure: ${validator_name}(${value})"
        echo "${_v_msg:-$_v_name must not contain spaces}" >&2
        return 1
    fi

    if [[ "$uppercase" -eq 1 ]]; then
        # se esiste una lettera a-z → fallisce
        if [[ "$value" =~ [a-z] ]]; then
            echo "Validation failure: ${validator_name}(${value})"
            echo "${_v_msg:-$_v_name must be uppercase}" >&2
            return 1
        fi
    fi

    if [[ "$lowercase" -eq 1 ]]; then
        # se esiste una lettera A-Z → fallisce
        if [[ "$value" =~ [A-Z] ]]; then
            echo "Validation failure: ${validator_name}(${value})"
            echo "${_v_msg:-$_v_name must be lowercase}" >&2
            return 1
        fi
    fi

    return 0
}


check_enum() {
    local value="$1"; shift

    local validator_name="check_enum"

    # reset comuni
    _validator_reset
    _v_other_opts=()

    # parse comuni (-name= -required= -msg=)
    _validator_parse_common "$@"

    # parse specifici: -one=VAL ripetibile
    local allowed=()
    local opt
    for opt in "${_v_other_opts[@]}"; do
        case "$opt" in
        -one=*) allowed+=("${opt#-one=}") ;;
        *)
            echo "check_enum: unknown option $opt" >&2
            ;;
        esac
    done

    # required?
    if [[ -z "$value" && "$_v_required" -eq 1 ]]; then
        echo "Validation failure: ${validator_name}(${value})"
        echo "${_v_msg:-$_v_name is required}" >&2
        return 1
    fi

    # se non è required e non c'è valore → ok
    if [[ -z "$value" ]]; then
        return 0
    fi

    # se non è stata passata nessuna lista, non ha senso
    if [[ ${#allowed[@]} -eq 0 ]]; then
        echo "Validation failure: ${validator_name}(${value})"
        echo "check_enum: no allowed values provided for $_v_name" >&2
        return 1
    fi

    # verifica appartenenza
    local a
    for a in "${allowed[@]}"; do
        if [[ "$value" == "$a" ]]; then
            return 0
        fi
    done

    # non trovato
    if [[ -n "$_v_msg" ]]; then
        echo "Validation failure: ${validator_name}(${value})"
        echo "$_v_msg" >&2
    else
        echo "Validation failure: ${validator_name}(${value})"
        echo "$_v_name must be one of: ${allowed[*]}" >&2
    fi
    return 1
}

check_file() {
    local value="$1"; shift

    local validator_name="check_file"

    # reset comuni
    _validator_reset
    _v_other_opts=()

    # parse comuni (-name= -required= -msg=)
    _validator_parse_common "$@"

    # opzioni specifiche
    local mustexist=1      # di default se lo passi lo vogliamo trovare
    local readable=0
    local writable=0
    local ftype=""         # file | dir

    local opt
    for opt in "${_v_other_opts[@]}"; do
        case "$opt" in
        -mustexist=*) mustexist="${opt#-mustexist=}" ;;
        -readable=*)  readable="${opt#-readable=}" ;;
        -writable=*)  writable="${opt#-writable=}" ;;
        -type=*)      ftype="${opt#-type=}" ;;
        *)
            echo "check_file: unknown option $opt" >&2
            ;;
        esac
    done

    # required?
    if [[ -z "$value" && "$_v_required" -eq 1 ]]; then
        echo "Validation failure: ${validator_name}(${value})"
        echo "${_v_msg:-$_v_name is required}" >&2
        return 1
    fi

    # non required e vuoto → ok
    if [[ -z "$value" ]]; then
        return 0
    fi

    # esistenza
    if [[ "$mustexist" -eq 1 ]] && [[ ! -e "$value" ]]; then
        echo "Validation failure: ${validator_name}(${value})"
        echo "${_v_msg:-$_v_name does not exist: $value}" >&2
        return 1
    fi

    # tipo
    if [[ -n "$ftype" ]]; then
        case "$ftype" in
        file)
            if [[ ! -f "$value" ]]; then
                echo "Validation failure: ${validator_name}(${value})"
                echo "${_v_msg:-$_v_name must be a regular file}" >&2
                return 1
            fi
            ;;
        dir)
            if [[ ! -d "$value" ]]; then
                echo "Validation failure: ${validator_name}(${value})"
                echo "${_v_msg:-$_v_name must be a directory}" >&2
                return 1
            fi
            ;;
        *)
            echo "Validation failure: ${validator_name}(${value})"
            echo "check_file: invalid -type=$ftype (use file|dir)" >&2
            return 1
            ;;
        esac
    fi

    # permessi
    if [[ "$readable" -eq 1 ]] && [[ ! -r "$value" ]]; then
        echo "Validation failure: ${validator_name}(${value})"
        echo "${_v_msg:-$_v_name must be readable}" >&2
        return 1
    fi
    if [[ "$writable" -eq 1 ]] && [[ ! -w "$value" ]]; then
        echo "Validation failure: ${validator_name}(${value})"
        echo "${_v_msg:-$_v_name must be writable}" >&2
        return 1
    fi

    return 0
}


# Rileva se stiamo girando in un ambiente Docker rootless (tipicamente userns remapping).
# Nota: questa funzione ha senso soprattutto quando dentro al container risultiamo UID=0.
# Ritorna:
#   0 -> rootless
#   1 -> non rootless / non determinabile
docker_is_rootless() {
    # Se non siamo root nel container, non è il caso d'uso di “rootless vs root vera”
    # per le operazioni privilegiate: trattiamo come non-rootless.
    if [[ "$(id -u)" -ne 0 ]]; then
        return 1
    fi

    # In rootless/userns tipicamente la mappa UID non è identity (0 -> host_uid != 0)
    # Esempi:
    #   rootful:  0 0 4294967295
    #   rootless: 0 1000 1
    local uid_map_file="/proc/self/uid_map"
    if [[ ! -r "$uid_map_file" ]]; then
        return 1
    fi

    local inside outside range
    read -r inside outside range < <(awk 'NR==1 {print $1, $2, $3}' "$uid_map_file" 2>/dev/null) || true

    # Non determinabile
    if [[ -z "${inside:-}" || -z "${outside:-}" || -z "${range:-}" ]]; then
        return 1
    fi

    # “root vera” (rootful) tende ad avere 0->0 su un range molto grande.
    # Euristiche:
    #  - Se 0 mappa su un UID host != 0, è fortemente indicativo di rootless/userns.
    #  - Se 0->0 ma il range NON è quello tipico (4294967295), è spesso userns remapping.
    if [[ "$inside" == "0" && "$outside" != "0" ]]; then
        return 0
    fi
    if [[ "$inside" == "0" && "$outside" == "0" && "$range" != "4294967295" ]]; then
        return 0
    fi

    return 1
}


docker_is_rootful() {
    docker_is_rootless && return 1
    return 0
}

