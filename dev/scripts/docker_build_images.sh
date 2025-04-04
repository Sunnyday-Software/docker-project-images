#!/bin/bash

docker compose build bash --env-from-file .env.docker
docker compose build --env-from-file .env.docker