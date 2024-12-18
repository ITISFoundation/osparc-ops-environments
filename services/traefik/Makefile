.DEFAULT_GOAL := help

# Internal VARIABLES ------------------------------------------------
# STACK_NAME defaults to name of the current directory. Should not to be changed if you follow GitOps operating procedures.
STACK_NAME = $(notdir $(shell pwd))
TEMP_COMPOSE=.stack.${STACK_NAME}.yaml
REPO_BASE_DIR := $(shell git rev-parse --show-toplevel)

# TARGETS --------------------------------------------------
include ${REPO_BASE_DIR}/scripts/common.Makefile


.PHONY: up-local
up-local: .init .create_secrets .env ${TEMP_COMPOSE}-local ## Deploys the stack using provided certificates
	@docker stack deploy --with-registry-auth --prune --compose-file ${TEMP_COMPOSE}-local ${STACK_NAME}

.PHONY: up-letsencrypt-http
up-letsencrypt-http: .init .env ${TEMP_COMPOSE}-letsencrypt-http ## Deploys the stack with let's encrypt http challenge
	@docker stack deploy --with-registry-auth --prune --compose-file ${TEMP_COMPOSE}-letsencrypt-http ${STACK_NAME}

.PHONY: up-letsencrypt-dns
up-letsencrypt-dns: .init .env ${TEMP_COMPOSE}-letsencrypt-dns ## Deploys the stack with let's encrypt dns challenge
	@docker stack deploy --with-registry-auth --prune --compose-file ${TEMP_COMPOSE}-dns ${STACK_NAME}

.PHONY: up-dalco
up-dalco: .init .env ${TEMP_COMPOSE}-dalco ## Deploys the stack on dalco cluster
	@docker stack deploy --with-registry-auth --prune --compose-file ${TEMP_COMPOSE}-dalco ${STACK_NAME}

.PHONY: up-public
up-public: .init .env ${TEMP_COMPOSE}-public ## Deploys the stack on dalco cluster
	@docker stack deploy --with-registry-auth --prune --compose-file ${TEMP_COMPOSE}-public ${STACK_NAME}

.PHONY: up-aws
up-aws: .init .env ${TEMP_COMPOSE}-aws ## Deploys the stack aws
	@docker stack deploy --with-registry-auth --prune --compose-file ${TEMP_COMPOSE}-aws ${STACK_NAME}

.PHONY: up-master ## Deploys the stack on master
up-master: .init .env ${TEMP_COMPOSE}-master ## Deploys the stack on dalco cluster
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
${TEMP_COMPOSE}-local: docker-compose.yml docker-compose.local.yml .env
	@set -o allexport; \
	source .env; \
	set +o allexport; \
	${REPO_BASE_DIR}/scripts/docker-stack-config.bash -e .env $< docker-compose.local.yml  > $@

.PHONY: ${TEMP_COMPOSE}-letsencrypt-http
${TEMP_COMPOSE}-letsencrypt-http: docker-compose.yml docker-compose.letsencrypt.http.yml .env
	@set -o allexport; \
	source .env; \
	set +o allexport; \
	${REPO_BASE_DIR}/scripts/docker-stack-config.bash -e .env $< docker-compose.letsencrypt.http.yml > $@

.PHONY: ${TEMP_COMPOSE}-letsencrypt-dns
${TEMP_COMPOSE}-letsencrypt-dns: docker-compose.yml docker-compose.letsencrypt.dns.yml .env
	@set -o allexport; \
	source .env; \
	set +o allexport; \
	${REPO_BASE_DIR}/scripts/docker-stack-config.bash -e .env $< docker-compose.letsencrypt.dns.yml > $@

.PHONY: ${TEMP_COMPOSE}-aws
${TEMP_COMPOSE}-aws: docker-compose.yml docker-compose.aws.yml .env
	@set -o allexport; \
	source .env; \
	set +o allexport; \
	${REPO_BASE_DIR}/scripts/docker-stack-config.bash -e .env $< docker-compose.aws.yml > $@

.PHONY: ${TEMP_COMPOSE}-dalco
${TEMP_COMPOSE}-dalco: docker-compose.yml docker-compose.dalco.yml .env
	@set -o allexport; \
	source .env; \
	set +o allexport; \
	${REPO_BASE_DIR}/scripts/docker-stack-config.bash -e .env $< docker-compose.dalco.yml > $@

.PHONY: ${TEMP_COMPOSE}-public
${TEMP_COMPOSE}-public: docker-compose.yml docker-compose.public.yml .env
	@set -o allexport; \
	source .env; \
	set +o allexport; \
	${REPO_BASE_DIR}/scripts/docker-stack-config.bash -e .env $< docker-compose.public.yml > $@

.PHONY: ${TEMP_COMPOSE}-master
${TEMP_COMPOSE}-master: docker-compose.yml docker-compose.master.yml .env
	@set -o allexport; \
	source .env; \
	set +o allexport; \
	${REPO_BASE_DIR}/scripts/docker-stack-config.bash -e .env $< docker-compose.master.yml > $@

.PHONY: docker-compose.letsencrypt.dns.yml
docker-compose.letsencrypt.dns.yml: .venv .env
	@$(call jinja, docker-compose.letsencrypt.dns.yml.j2, .env, docker-compose.letsencrypt.dns.yml.unlinted) && \
	$(_yq) docker-compose.letsencrypt.dns.yml.unlinted > docker-compose.letsencrypt.dns.yml; \
	rm docker-compose.letsencrypt.dns.yml.unlinted >/dev/null 2>&1;

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
