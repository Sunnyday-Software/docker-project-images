#!/bin/bash

# Source the error handler
source "$(dirname "$0")/error_handler.sh"

export COMPOSE_PARALLEL_LIMIT=1

docker compose build bash
docker compose build
