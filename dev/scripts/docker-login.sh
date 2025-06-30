#!/bin/bash

# Source the error handler
source "$(dirname "$0")/error_handler.sh"

source .env

COMPOSE_FILE="./docker-compose.yml"
ROOT_DIR="dev/docker"
export DOCKER_CONFIG=/workdir/.docker

if [ -z "$DOCKERHUB_USERNAME" ]; then
  echo "❌ Errore: DOCKERHUB_USERNAME non è valorizzata o è vuota!"
  exit 1
else
  echo "✅ DOCKERHUB_USERNAME è valorizzata!"
fi

# Only check for DOCKERHUB_TOKEN and perform login in CI environment
if [ "$CI" = "true" ]; then
  echo "🔍 CI environment detected, performing Docker login"

  if [ -z "$DOCKERHUB_TOKEN" ]; then
    echo "❌ Errore: DOCKERHUB_TOKEN non è valorizzata o è vuota!"
    exit 1
  else
    echo "✅ DOCKERHUB_TOKEN è valorizzata!"
  fi

  echo "$DOCKERHUB_TOKEN" | docker login -u "$DOCKERHUB_USERNAME" --password-stdin
else
  echo "🔍 Non-CI environment detected, skipping Docker login"
fi
