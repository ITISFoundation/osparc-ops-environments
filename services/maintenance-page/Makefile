.DEFAULT_GOAL := help


# Internal VARIABLES ------------------------------------------------
# STACK_NAME defaults to name of the current directory. Should not to be changed if you follow GitOps operating procedures.
STACK_NAME = $(notdir $(shell pwd))
TEMP_COMPOSE=.stack.${STACK_NAME}.yaml
REPO_BASE_DIR := $(shell git rev-parse --show-toplevel)

# TARGETS --------------------------------------------------
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

.PHONY: docker-compose.yml
docker-compose.yml: venv .env
	@$(call jinja, docker-compose.yml.j2, .env, docker-compose.yml.unlinted) && \
	$(_yq) docker-compose.yml.unlinted > docker-compose.yml; \
	rm docker-compose.yml.unlinted >/dev/null 2>&1;

.PHONY: ${TEMP_COMPOSE}
${TEMP_COMPOSE}: docker-compose.yml .env
	${REPO_BASE_DIR}/scripts/docker-stack-config.bash -e .env $< > $@
