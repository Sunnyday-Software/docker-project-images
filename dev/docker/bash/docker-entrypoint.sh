#!/usr/bin/dumb-init /usr/bin/bash

# https://github.com/Yelp/dumb-init

set -e

# Prevent core dumps
ulimit -c 0

if [ "$(id -u)" = '0' ]; then
  # then restart script as bashuser user
	exec gosu bashuser "$BASH_SOURCE" "$@"
fi

SSH_KEY="$HOME/.ssh/id_rsa"

# Generate SSH key if it does not exist
if [ ! -f "$SSH_KEY" ]; then
    echo "SSH key not found, generating a new SSH key..."
    ssh-keygen -t rsa -b 4096 -f "$SSH_KEY" -N ""
fi

# Source all Bash files in the commons_functions directory
for file in ~/.bashrc.d/*.sh; do
    [ -f "$file" ] && . "$file"
done

exec "$@"

