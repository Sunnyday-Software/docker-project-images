#!make

$(shell find ./dev/scripts -type f -name "*.sh" -exec chmod +x {} + > /dev/null 2>&1)
$(shell find ./dev/scripts -type f -name "*.sh" -exec dos2unix {} + > /dev/null 2>&1)

# Target predefinito
.DEFAULT_GOAL := help

DOCKER_RUN := docker compose run --rm --remove-orphans --env-from-file .env

.PHONY: always build-images

build-images: ## costruisce le immagini docker
	@[ -f dev/scripts/docker_image_verification.sh ] && ./dev/scripts/docker_image_verification.sh

always: build-images

debug-in-vm:
	./dev/scripts/debug-env.sh

docker-login: ## docker login
	./dev/scripts/docker-login.sh

push-images: ## push delle immagini
	./dev/scripts/push-images.sh

push-multiarch: ## push multi-arch manifests
	./dev/scripts/push-multiarch.sh

help: always
	@echo "\n Available tasks:\n"
	@{ \
		grep -hE '^[a-zA-Z0-9_-]+:.*## .*$$' $(MAKEFILE_LIST); \
	} | sort | awk 'BEGIN {FS = ":.*## "}; {printf "  %-25s %s\n", $$1, $$2}'
	@echo ""
