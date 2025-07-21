.DEFAULT_GOAL := help

# Internal VARIABLES ------------------------------------------------
# STACK_NAME defaults to name of the current directory.
STACK_NAME = $(notdir $(shell pwd))
DOCKER_MINIO_ACCESS_KEY = $(shell docker secret inspect --format {{.Spec.Name}} minio_secret_key 2>/dev/null)
DOCKER_MINIO_SECRET_KEY = $(shell docker secret inspect --format {{.Spec.Name}} minio_access_key 2>/dev/null)
TEMP_COMPOSE=.stack.${STACK_NAME}.yaml
REPO_BASE_DIR := $(shell git rev-parse --show-toplevel)

# TARGETS --------------------------------------------------
include ${REPO_BASE_DIR}/scripts/common.Makefile

.PHONY: up
up: .init .env ${TEMP_COMPOSE} .create-secrets
	@docker stack deploy --with-registry-auth --prune --compose-file ${TEMP_COMPOSE} $(STACK_NAME)

.PHONY: up-dalco
up-dalco: up

.PHONY: up-master
up-master: up

.PHONY: up-local
up-local: up

.PHONY: ${TEMP_COMPOSE}
${TEMP_COMPOSE}: docker-compose.yaml venv .env
	@${REPO_BASE_DIR}/scripts/docker-stack-config.bash -e .env docker-compose.yaml > $@


.create-secrets:
	@$(if $(DOCKER_MINIO_ACCESS_KEY), \
		, \
		set -o allexport; source .env; set +o allexport; echo "$${MINIO_ACCESS_KEY}" | docker secret create minio_access_key -  2>/dev/null; \
	)
	@$(if $(DOCKER_MINIO_SECRET_KEY), \
		,							\
		set -o allexport; source .env; set +o allexport; echo "$${MINIO_SECRET_KEY}" | docker secret create minio_secret_key -  2>/dev/null; \
	)
