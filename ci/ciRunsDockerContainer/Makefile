# Makefile including function used by every services
include .env
## DOCKER TAGS  -------------------------------

.PHONY: tag-local tag-version tag-latest build-container

tag-version: .env ## Tags 'local/${DOCKER_IMAGE_NAME}):dev' images as versioned '${DOCKER_REGISTRY}/${DOCKER_IMAGE_NAME}:${DOCKER_IMAGE_TAG}'
	docker tag local/${DOCKER_IMAGE_NAME}:dev ${DOCKER_REGISTRY}/${DOCKER_IMAGE_NAME}:${DOCKER_IMAGE_TAG};

tag-latest: .env ## Tags last locally built production images as '${DOCKER_REGISTRY}/{service}:latest'
	docker tag local/${DOCKER_IMAGE_NAME}:dev ${DOCKER_REGISTRY}/${DOCKER_IMAGE_NAME}:latest;

build-container: .env ## Build the common docker container that runs the CI runs
	docker build  --no-cache -t local/${DOCKER_IMAGE_NAME}:dev .;


## DOCKER PULL/PUSH  -------------------------------
#
# TODO: do not allow pushing modified/untracked
# TODO: do not allow pushing disceted
#

.PHONY: push-version push-latest

push-latest: tag-latest
	@set -o allexport; \
	source $(realpath $(CURDIR)/.env); \
	set +o allexport; \
	export DOCKER_IMAGE_TAG=latest; \
	$(MAKE) push-version

# below BUILD_TARGET gets overwritten but is required when merging yaml files
push-version: tag-version
	# pushing '${DOCKER_REGISTRY}/${DOCKER_IMAGE_NAME}:${DOCKER_IMAGE_TAG}'
	@set -o allexport; \
	source $(realpath $(CURDIR)/.env); \
	set +o allexport; \
	export DOCKER_IMAGE_TAG=latest; \
	./dockerhub_login.bash && \
	docker compose --file docker-compose-deploy.yml push
