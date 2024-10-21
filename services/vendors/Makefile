.DEFAULT_GOAL := help

# Internal VARIABLES ------------------------------------------------
# STACK_NAME defaults to name of the current directory. Should not to be changed if you follow GitOps operating procedures.
STACK_NAME = $(notdir $(shell pwd))
TEMP_COMPOSE=.stack.${STACK_NAME}.yaml
REPO_BASE_DIR := $(shell git rev-parse --show-toplevel)

# TARGETS --------------------------------------------------
include ${REPO_BASE_DIR}/scripts/common.Makefile

.PHONY: up ## Deploys registry stack
up: ${TEMP_COMPOSE} .init .env
	docker stack deploy --with-registry-auth --prune --compose-file $< ${STACK_NAME}

.PHONY: up-dalco ## Deploys registry stack for Dalco Cluster
up-dalco: up

.PHONY: up-aws
up-aws: up

.PHONY: up-master ## Deploys registry on master cluster
up-master: up

.PHONY: up-public ## Deploys registry on public cluster
up-public: up

.PHONY: up-local ## Deploys registry on local deployment
up-local: up

# Helpers -------------------------------------------------

.PHONY: ${TEMP_COMPOSE}
${TEMP_COMPOSE}: docker-compose.yml .env
	${REPO_BASE_DIR}/scripts/docker-stack-config.bash -e .env $< > $@
