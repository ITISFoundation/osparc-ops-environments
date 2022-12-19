.DEFAULT_GOAL := help


# Internal VARIABLES ------------------------------------------------
# STACK_NAME defaults to name of the current directory. Should not to be changed if you follow GitOps operating procedures.
STACK_NAME = $(notdir $(shell pwd))
SWARM_HOSTS = $(shell docker node ls --format={{.Hostname}} 2>/dev/null)
TEMP_COMPOSE=.stack.${STACK_NAME}.yaml
REPO_BASE_DIR := $(shell git rev-parse --show-toplevel)

# Makefile including function used by every services
include ${REPO_BASE_DIR}/scripts/common.Makefile

.PHONY: up ## Deploys maintenance page stack
up: .init .env ${TEMP_COMPOSE}
	docker stack deploy --with-registry-auth --prune --compose-file ${TEMP_COMPOSE} ${STACK_NAME}

.PHONY: up-dalco ## Deploys maintenance page stack for Dalco Cluster
up-dalco: up

.PHONY: up-local ## Deploys maintenance page stack for local deployment
up-local: up

.PHONY: up-public ## Deploys maintenance page stack for public access
up-public: up

.PHONY: up-aws ## Deploys maintenance page stack for aws Cluster
up-aws: up

.PHONY: up-master ## Deploys maintenance page stack for Master Cluster
up-master: up

# Helpers -------------------------------------------------

.PHONY: ${TEMP_COMPOSE}
${TEMP_COMPOSE}: docker-compose.yml
	docker-compose -f $< --env-file=.env --log-level=ERROR config > $@
