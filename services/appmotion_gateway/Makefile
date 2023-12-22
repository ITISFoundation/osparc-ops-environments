.DEFAULT_GOAL := help



# Internal VARIABLES ------------------------------------------------
# STACK_NAME defaults to name of the current directory. Should not to be changed if you follow GitOps operating procedures.
STACK_NAME = $(notdir $(shell pwd))
TEMP_COMPOSE=.stack.${STACK_NAME}.yaml
REPO_BASE_DIR := $(shell git rev-parse --show-toplevel)

# TARGETS --------------------------------------------------
include ${REPO_BASE_DIR}/scripts/common.Makefile

.PHONY: up-aws ## Deploys stack on aws
up-aws: .init .env ${TEMP_COMPOSE}-aws .api_env
	@docker stack deploy --with-registry-auth --prune --compose-file ${TEMP_COMPOSE}-aws ${STACK_NAME}

.PHONY: up-local ## Deploys stack on local
up-local: .init .env ${TEMP_COMPOSE}-local .api_env
	@docker stack deploy --with-registry-auth --prune --compose-file ${TEMP_COMPOSE}-local ${STACK_NAME}

# Helpers -------------------------------------------------

.PHONY: ${TEMP_COMPOSE}-aws
${TEMP_COMPOSE}-aws: docker-compose.yml docker-compose.aws.yml
	@${REPO_BASE_DIR}/scripts/docker-compose-config.bash -e .env $< docker-compose.aws.yml > $@

.PHONY: ${TEMP_COMPOSE}-local
${TEMP_COMPOSE}-local: docker-compose.yml docker-compose.local.yml
	@${REPO_BASE_DIR}/scripts/docker-compose-config.bash -e .env $< docker-compose.local.yml > $@


.api_env: .env template.api_env ## resolves '.api_env' using '.env'
	@set -o allexport; source $<; set +o allexport; envsubst < $(word 2,$^) > $@
