#!make

$(shell find ./dev/scripts -type f -name "*.sh" -exec chmod +x {} + > /dev/null 2>&1)
$(shell find ./dev/scripts -type f -name "*.sh" -exec dos2unix {} + > /dev/null 2>&1)

# Target predefinito
.DEFAULT_GOAL := help

ifeq ($(CI), true)
	DOCKER_RUN := docker compose run --rm --remove-orphans --env-from-file .env.docker
else
	DOCKER_RUN := docker compose run --rm --remove-orphans --env-from-file .env
endif


DOCKER_RUN := docker compose  run --rm --remove-orphans --env-from-file .env

.PHONY: always build-images

build-images: # costruisce le immagini docker
	@[ -f dev/scripts/docker_image_verification.sh ] && ./dev/scripts/docker_image_verification.sh

always: build-images

debug-in-vm:
	./dev/scripts/debug-env.sh

docker-login:
	./dev/scripts/docker-login.sh

push-images:
	./dev/scripts/push-images.sh

help: always
	@echo "\n Available tasks:\n"
	@{ \
		grep -hE '^[a-zA-Z0-9_-]+:.*## .*$$' $(MAKEFILE_LIST); \
	} | sort | awk 'BEGIN {FS = ":.*## "}; {printf "  %-25s %s\n", $$1, $$2}'
	@echo ""


