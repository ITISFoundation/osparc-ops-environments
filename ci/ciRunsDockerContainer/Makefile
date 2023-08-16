# Makefile including function used by every services
include ../../scripts/common.Makefile
## DOCKER TAGS  -------------------------------

.PHONY: tag-local tag-version tag-latest build-container

tag-version: .env ## Tags 'local/${DOCKER_IMAGE_NAME}):dev' images as versioned '${DOCKER_REGISTRY}/${DOCKER_IMAGE_NAME}:${DOCKER_IMAGE_TAG}'
	@set -o allexport; \
	source $(realpath $(CURDIR)/.env); \
	set +o allexport; \
	docker tag local/$$DOCKER_IMAGE_NAME:dev $$DOCKER_REGISTRY/$$DOCKER_IMAGE_NAME:$$DOCKER_IMAGE_TAG;

tag-latest: .env ## Tags last locally built production images as '${DOCKER_REGISTRY}/{service}:latest'
	set -o allexport; \
	source $(realpath $(CURDIR)/.env); \
	set +o allexport; \
	docker tag local/$$DOCKER_IMAGE_NAME:dev $$DOCKER_REGISTRY/$$DOCKER_IMAGE_NAME:latest;

build-container: .env ## Build the common docker container that runs the CI runs
	@set -o allexport; \
	source $(realpath $(CURDIR)/.env); \
	set +o allexport; \
	docker build  --no-cache -t local/$$DOCKER_IMAGE_NAME:dev .;

.PHONY: build
build: build-container ## Build the docker container that runs the CI runs
## DOCKER PULL/PUSH  -------------------------------

#

.PHONY: push-version push-latest

push-latest: tag-latest
	@set -o allexport; \
	source $(realpath $(CURDIR)/.env); \
	set +o allexport; \
	export DOCKER_IMAGE_TAG=latest; \
	$(MAKE) push-version

push-version: tag-version
	@set -o allexport; \
	source $(realpath $(CURDIR)/.env); \
	set +o allexport; \
	echo "Pushing $$DOCKER_REGISTRY/$$DOCKER_IMAGE_NAME:$$DOCKER_IMAGE_TAG"; \
	./dockerhub_login.bash && \
	docker compose --file docker-compose-deploy.yml push
