.DEFAULT_GOAL := help

REPO_BASE_DIR := $(shell git rev-parse --show-toplevel)

# TARGETS --------------------------------------------------
include ${REPO_BASE_DIR}/scripts/common.Makefile
include $(REPO_CONFIG_LOCATION)

# Internal VARIABLES ------------------------------------------------
# STACK_NAME defaults to name of the current directory. Should not to be changed if you follow GitOps operating procedures.
STACK_NAME = $(notdir $(shell pwd))
TEMP_COMPOSE=.stack.${STACK_NAME}.yaml

.PHONY: up ## Deploys pg-backup stack
up: .init .env ${TEMP_COMPOSE}  ## Deploys pg-backup stack
	docker stack deploy --with-registry-auth --compose-file ${TEMP_COMPOSE} ${STACK_NAME}

.PHONY: up-dalco ## Deploys pg-backup stack for Dalco Cluster
up-dalco: up

.PHONY: up-local ## Deploys pg-backup stack for local deployment
up-local: up

.PHONY: up-master ## Deploys pg-backup stack for Master Cluster
up-master: up-dalco

.PHONY: up-public ## Deploys pg-backup stack for public access cluster
up-public: up

# Helpers -------------------------------------------------

.PHONY: ${TEMP_COMPOSE}
${TEMP_COMPOSE}: docker-compose.yml venv .env
	${REPO_BASE_DIR}/scripts/docker-stack-config.bash -e .env $< > $@
