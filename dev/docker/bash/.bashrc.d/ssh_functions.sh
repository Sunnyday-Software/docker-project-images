#!/bin/bash

#Function to check SSH connection
function can_ssh_without_password {
    local destination=$1

    # Prova a fare SSH usando BatchMode=yes per disabilitare il prompt della password
    ssh -o BatchMode=yes -o ConnectTimeout=5 "$destination" 'echo Access successful' &>/dev/null

    if [[ $? -eq 0 ]]; then
        echo "Connessione SSH senza password riuscita a $destination."
        return 0
    else
        echo "Impossibile connettersi a $destination senza password."
        return 1
    fi
}