#!/bin/bash

source .env

COMPOSE_FILE="./docker-compose.yml"
ROOT_DIR="dev/docker"

echo "Docker login"
echo "$DOCKERHUB_TOKEN" | docker login -u "$DOCKERHUB_USERNAME" --password-stdin
