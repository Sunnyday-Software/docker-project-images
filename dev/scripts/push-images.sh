#!/bin/bash

source .env

COMPOSE_FILE="docker-compose.yml"

echo "🐳 Docker Compose: PUSH"
docker compose -f "$COMPOSE_FILE" push