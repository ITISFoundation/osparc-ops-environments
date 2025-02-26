.DEFAULT_GOAL := help

# Internal VARIABLES ------------------------------------------------
# STACK_NAME defaults to name of the current directory. Should not to be changed if you follow GitOps operating procedures.
STACK_NAME = $(notdir $(shell pwd))
TEMP_COMPOSE=.stack.${STACK_NAME}.yaml
REPO_BASE_DIR := $(shell git rev-parse --show-toplevel)

DOCKER_STACK_DEPLOY_COMMON_DEPENDENCIES = .api_env.secret \
										  prune-docker-stack-configs  \
										  prune-docker-stack-secrets

# TARGETS --------------------------------------------------
include ${REPO_BASE_DIR}/scripts/common.Makefile

.PHONY: up-aws ## Deploys stack on aws
up-aws: .init .env ${TEMP_COMPOSE}-aws ${DOCKER_STACK_DEPLOY_COMMON_DEPENDENCIES}
	@docker stack deploy --with-registry-auth --prune --compose-file ${TEMP_COMPOSE}-aws ${STACK_NAME}

.PHONY: up-master ## Deploys stack on master
up-master: .init .env ${TEMP_COMPOSE}-master ${DOCKER_STACK_DEPLOY_COMMON_DEPENDENCIES}
	@docker stack deploy --with-registry-auth --prune --compose-file ${TEMP_COMPOSE}-master ${STACK_NAME}

.PHONY: up-dalco ## Deploys stack on dalco
up-dalco: .init .env ${TEMP_COMPOSE}-master ${DOCKER_STACK_DEPLOY_COMMON_DEPENDENCIES}
	@docker stack deploy --with-registry-auth --prune --compose-file ${TEMP_COMPOSE}-dalco ${STACK_NAME}

.PHONY: up-local ## Deploys stack on local
up-local: .init .env ${TEMP_COMPOSE}-local ${DOCKER_STACK_DEPLOY_COMMON_DEPENDENCIES}
	@docker stack deploy --with-registry-auth --prune --compose-file ${TEMP_COMPOSE}-local ${STACK_NAME}

# Helpers -------------------------------------------------

docker-compose.yml: .env .api_env.secret
	@$(call jinja, docker-compose.yml.j2, .env, docker-compose.yml.unlinted) && \
	$(_yq) docker-compose.yml.unlinted > docker-compose.yml; \
	rm docker-compose.yml.unlinted >/dev/null 2>&1;

.PHONY: ${TEMP_COMPOSE}-aws
${TEMP_COMPOSE}-aws: docker-compose.yml docker-compose.aws.yml
	@${REPO_BASE_DIR}/scripts/docker-stack-config.bash -e .env $< docker-compose.aws.yml > $@

.PHONY: ${TEMP_COMPOSE}-master
${TEMP_COMPOSE}-master: docker-compose.yml docker-compose.master.yml
	@${REPO_BASE_DIR}/scripts/docker-stack-config.bash -e .env $< docker-compose.master.yml > $@

.PHONY: ${TEMP_COMPOSE}-dalco
${TEMP_COMPOSE}-dalco: docker-compose.yml docker-compose.dalco.yml
	@${REPO_BASE_DIR}/scripts/docker-stack-config.bash -e .env $< docker-compose.dalco.yml > $@

.PHONY: ${TEMP_COMPOSE}-local
${TEMP_COMPOSE}-local: docker-compose.yml docker-compose.local.yml
	@${REPO_BASE_DIR}/scripts/docker-stack-config.bash -e .env $< docker-compose.local.yml > $@

.api_env.secret: .env template.api_env ## resolves '.api_env.secret' using '.env'
	@set -o allexport; source $<; set +o allexport; envsubst < $(word 2,$^) > $@
