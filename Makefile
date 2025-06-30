#!make

$(shell find ./dev/scripts -type f -name "*.sh" -exec chmod +x {} + > /dev/null 2>&1)
$(shell find ./dev/scripts -type f -name "*.sh" -exec dos2unix {} + > /dev/null 2>&1)

# Target predefinito
.DEFAULT_GOAL := help

ifeq ($(CI), true)
	DOCKER_RUN := docker compose run --rm --remove-orphans --env-from-file .env.ci
else
	DOCKER_RUN := docker compose run --rm --remove-orphans --env-from-file .env
endif

.PHONY: always build-images

build-images: ## costruisce le immagini docker
	@[ -f dev/scripts/gen-md5-and-build.sh ] && ./dev/scripts/gen-md5-and-build.sh

always: build-images

debug-in-vm:
	./dev/scripts/debug-env.sh

docker-login: ## docker login
	$(DOCKER_RUN) make ./dev/scripts/docker-login.sh

push-images: ## push delle immagini
	$(DOCKER_RUN) make ./dev/scripts/push-images.sh

help: always
	@echo "\n Available tasks:\n"
	@{ \
		grep -hE '^[a-zA-Z0-9_-]+:.*## .*$$' $(MAKEFILE_LIST); \
	} | sort | awk 'BEGIN {FS = ":.*## "}; {printf "  %-25s %s\n", $$1, $$2}'
	@echo ""
