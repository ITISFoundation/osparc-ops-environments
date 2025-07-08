.DEFAULT_GOAL := help

# Internal VARIABLES ------------------------------------------------
# STACK_NAME defaults to name of the current directory. Should not to be changed if you follow GitOps operating procedures.
STACK_NAME = $(notdir $(shell pwd))
TEMP_COMPOSE=.stack.${STACK_NAME}.yaml
REPO_BASE_DIR := $(shell git rev-parse --show-toplevel)

# TARGETS --------------------------------------------------
include ${REPO_BASE_DIR}/scripts/common.Makefile

.PHONY: up-local
up-local: .init .create_secrets ${TEMP_COMPOSE}-local prune-docker-stack-configs ## Deploys the stack using provided certificates
	@docker stack deploy --with-registry-auth --prune --compose-file ${TEMP_COMPOSE}-local ${STACK_NAME}

.PHONY: up-dalco
up-dalco: .init ${TEMP_COMPOSE}-dalco prune-docker-stack-configs ## Deploys the stack on dalco cluster
	@docker stack deploy --with-registry-auth --prune --compose-file ${TEMP_COMPOSE}-dalco ${STACK_NAME}

.PHONY: up-public
up-public: .init ${TEMP_COMPOSE}-public prune-docker-stack-configs ## Deploys the stack on dalco cluster
	@docker stack deploy --with-registry-auth --prune --compose-file ${TEMP_COMPOSE}-public ${STACK_NAME}

.PHONY: up-aws
up-aws: .init ${TEMP_COMPOSE}-aws prune-docker-stack-configs ## Deploys the stack aws
	@docker stack deploy --with-registry-auth --prune --compose-file ${TEMP_COMPOSE}-aws ${STACK_NAME}

.PHONY: up-master ## Deploys the stack on master
up-master: .init ${TEMP_COMPOSE}-master prune-docker-stack-configs ## Deploys the stack on dalco cluster
	@docker stack deploy --with-registry-auth --prune --compose-file ${TEMP_COMPOSE}-master ${STACK_NAME}

# Helpers -------------------------------------------------

traefik_dynamic_config.yml:
	$(eval CONFIG_DIR=$(shell dirname ${REPO_CONFIG_LOCATION}))
	$(eval TRAEFIK_DYN_CFG=$(CONFIG_DIR)/$@)
	@if [ ! -f $(TRAEFIK_DYN_CFG) ]; then \
		echo "Error: file does not exist $(TRAEFIK_DYN_CFG)" >&2; \
		exit 1; \
	fi
	@cp $(TRAEFIK_DYN_CFG) $@


.PHONY: ${TEMP_COMPOSE}-local
${TEMP_COMPOSE}-local: docker-compose.yml docker-compose.local.yml .env traefik_dynamic_config.yml
	@set -o allexport; \
	source .env; \
	set +o allexport; \
	${REPO_BASE_DIR}/scripts/docker-stack-config.bash -e .env $< docker-compose.local.yml  > $@

.PHONY: ${TEMP_COMPOSE}-aws
${TEMP_COMPOSE}-aws: docker-compose.yml .env
	@set -o allexport; \
	source .env; \
	set +o allexport; \
	${REPO_BASE_DIR}/scripts/docker-stack-config.bash -e .env $< > $@

.PHONY: ${TEMP_COMPOSE}-dalco
${TEMP_COMPOSE}-dalco: docker-compose.yml .env
	@set -o allexport; \
	source .env; \
	set +o allexport; \
	${REPO_BASE_DIR}/scripts/docker-stack-config.bash -e .env $< > $@

.PHONY: ${TEMP_COMPOSE}-public
${TEMP_COMPOSE}-public: docker-compose.yml .env
	@set -o allexport; \
	source .env; \
	set +o allexport; \
	${REPO_BASE_DIR}/scripts/docker-stack-config.bash -e .env $< > $@

.PHONY: ${TEMP_COMPOSE}-master
${TEMP_COMPOSE}-master: docker-compose.yml .env
	@set -o allexport; \
	source .env; \
	set +o allexport; \
	${REPO_BASE_DIR}/scripts/docker-stack-config.bash -e .env $< > $@

.PHONY: docker-compose.yml
docker-compose.yml: traefik_dynamic_config.yml .venv .env
	@$(call jinja, docker-compose.yml.j2, .env, docker-compose.yml.unlinted) && \
	$(_yq) docker-compose.yml.unlinted > docker-compose.yml; \
	rm docker-compose.yml.unlinted >/dev/null 2>&1;

.PHONY: .create_secrets
.create_secrets: $(REPO_BASE_DIR)/certificates/domain.crt $(REPO_BASE_DIR)/certificates/domain.key $(REPO_BASE_DIR)/certificates/rootca.crt
	@if [[ ! $$(docker secret ls | grep -w domain.crt) ]]; then docker secret create domain.crt $(REPO_BASE_DIR)/certificates/domain.crt; fi;
	@if [[ ! $$(docker secret ls | grep -w domain.key) ]]; then docker secret create domain.key $(REPO_BASE_DIR)/certificates/domain.key; fi;
	@if [[ ! $$(docker secret ls | grep -w rootca.crt) ]]; then if [ ! -f $(REPO_BASE_DIR)/certificates/rootca.crt ]; then cp $(REPO_BASE_DIR)/certificates/domain.crt $(REPO_BASE_DIR)/certificates/rootca.crt; fi; docker secret create rootca.crt $(REPO_BASE_DIR)/certificates/rootca.crt; fi;
	@if [[ ! $$(docker secret ls | grep -w storageca.crt) ]]; then if [ ! -f $(REPO_BASE_DIR)/certificates/rootca.crt ]; then cp $(REPO_BASE_DIR)/certificates/domain.crt $(REPO_BASE_DIR)/certificates/rootca.crt; fi; docker secret create storageca.crt $(REPO_BASE_DIR)/certificates/rootca.crt; fi;
