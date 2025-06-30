#!/bin/bash

# Source the error handler
source "$(dirname "$0")/error_handler.sh"

docker compose build bash
docker compose build
