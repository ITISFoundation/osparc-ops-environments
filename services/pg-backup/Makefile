.DEFAULT_GOAL := help


# Internal VARIABLES ------------------------------------------------
# STACK_NAME defaults to name of the current directory. Should not to be changed if you follow GitOps operating procedures.
STACK_NAME = $(notdir $(shell pwd))
SWARM_HOSTS = $(shell docker node ls --format={{.Hostname}} 2>/dev/null)
TEMP_COMPOSE=.stack.${STACK_NAME}.yaml
REPO_BASE_DIR := $(shell git rev-parse --show-toplevel)

# TARGETS --------------------------------------------------
include ${REPO_BASE_DIR}/scripts/common.Makefile

.PHONY: up ## Deploys pg-backup stack
up: .init ${TEMP_COMPOSE}  ## Deploys pg-backup stack
	docker stack deploy --with-registry-auth --prune --compose-file ${TEMP_COMPOSE} ${STACK_NAME}

.PHONY: up-dalco ## Deploys pg-backup stack for Dalco Cluster
up-dalco: up

.PHONY: up-local ## Deploys pg-backup stack for local deployment
up-local: up

.PHONY: up-master ## Deploys pg-backup stack for Master Cluster
up-master: up-dalco

.PHONY: up-public ## Deploys pg-backup stack for public access cluster
up-public: .init ${TEMP_COMPOSE}-public
	docker stack deploy --with-registry-auth --prune --compose-file ${TEMP_COMPOSE}-public ${STACK_NAME}


# Helpers -------------------------------------------------

.PHONY: ${TEMP_COMPOSE}
${TEMP_COMPOSE}: docker-compose.yml
	@docker-compose -f $< --log-level=ERROR config > $@

.PHONY: ${TEMP_COMPOSE}-public
${TEMP_COMPOSE}-public: docker-compose.yml docker-compose.public.yml
	docker-compose -f $< -f docker-compose.public.yml --log-level=ERROR config > $@
