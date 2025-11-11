#!/bin/bash

source "/opt/bash_libs/import_libs.sh"
BRC_SSH_FUNCTIONS_TMUX_SH_S_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
lib_guard "BRC_SSH_FUNCTIONS_TMUX_SH_S_DIR" || { return 0 2>/dev/null || exit 0; }


SSH_KEY="$HOME/.ssh/id_rsa"

#Function to check SSH connection
function can_ssh_without_password {
    local destination=$1


    # Generate SSH key if it does not exist
    if [ ! -f "$SSH_KEY" ]; then
      log_debug "SSH key not found, generating a new SSH key..."
      ssh-keygen -t rsa -b 4096 -f "$SSH_KEY" -N ""
    fi

    # Prova a fare SSH usando BatchMode=yes per disabilitare il prompt della password
    ssh -o BatchMode=yes -o ConnectTimeout=5 "$destination" 'echo Access successful' &>/dev/null

    if [[ $? -eq 0 ]]; then
        log_debug "Connessione SSH senza password riuscita a $destination."
        return 0
    else
        log_err "Impossibile connettersi a $destination senza password."
        return 1
    fi
}




