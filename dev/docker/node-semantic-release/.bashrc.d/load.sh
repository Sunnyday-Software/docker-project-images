#!/bin/bash

# Verifica che non sia già stato caricato
if [[ -n "$__BASHRC_LOADED" ]]; then
    return
fi

export __BASHRC_LOADED=1

# Carica una sola volta tutti gli script in ~/.bashrc.d/
for file in ~/.bashrc.d/*.sh; do
    # Se il file è quello attuale ("load.sh"), saltalo per evitare auto-ricorsione
    if [[ "$(realpath "$file")" == "$(realpath "${BASH_SOURCE[0]}")" ]]; then
        continue
    fi
    [ -f "$file" ] && . "$file"
done