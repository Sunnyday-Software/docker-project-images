#!/usr/bin/env bash

# Library guard: if this library has already been sourced, stop here without error.
# Use 'return' when sourced/in a function; fall back to 'exit' when executed as a script.
if [[ -n "${__LIB_GUARD_CHECK_LIBS_SH}" ]]; then
    return 0 2>/dev/null || exit 0
fi

set -Euo pipefail

# Global counter used to assign incremental IDs to guards.
: "${__LIB_GUARD_COUNTER:=1}"
# Mark this specific library (libs.sh) as loaded.
__LIB_GUARD_CHECK_LIBS_SH=1

# lib_guard NAME
# Ensures a given logical library or section identified by NAME is loaded only once.
# - Returns 0 (success) and marks the guard if it wasn't set yet.
# - Returns 1 if the guard for NAME is already set (i.e., already loaded).
lib_guard() {
    local guard_name="__LIB_GUARD_CHECK_$1"

    # If the guard variable is already set/non-empty, signal "already loaded".
    if [[ -n "${!guard_name:-}" ]]; then
        return 1
    fi

    # Otherwise, increment the global counter and set a unique marker for this NAME.
    ((__LIB_GUARD_COUNTER++))
    declare -g "${guard_name}=${__LIB_GUARD_COUNTER}"
    return 0
}

