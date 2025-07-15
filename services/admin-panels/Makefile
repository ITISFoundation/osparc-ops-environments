.DEFAULT_GOAL := help



# Internal VARIABLES ------------------------------------------------
# STACK_NAME defaults to name of the current directory. Should not to be changed if you follow GitOps operating procedures.
STACK_NAME = $(notdir $(shell pwd))
TEMP_COMPOSE=.stack.${STACK_NAME}.yaml
REPO_BASE_DIR := $(shell git rev-parse --show-toplevel)

# TARGETS --------------------------------------------------
include ${REPO_BASE_DIR}/scripts/common.Makefile

# Helpers --------------------------------------------------
define custom-jinja
	@${VENV_BIN}/j2 --format=json $(1) $(2) -o $(3) \
	--filters $(REPO_BASE_DIR)/scripts/j2cli_global_filters.py
endef

.PHONY: .data.json
.data.json:
	@$(_tree) -J ${PWD}/data | jq ".[0]" > .data.json

.PHONY: docker-compose.yml
docker-compose.yml: docker-compose.yml.j2 venv .data.json .env jupyter_server_config.py
	$(call custom-jinja, $<, .data.json, tmp.yml)
	@${REPO_BASE_DIR}/scripts/docker-stack-config.bash tmp.yml > $@
	@rm tmp.yml

.PHONY: up
up: .init ${TEMP_COMPOSE} prune-docker-stack-configs ## Deploys jaeger stack
	@docker stack deploy --with-registry-auth --prune --compose-file ${TEMP_COMPOSE} ${STACK_NAME}

.PHONY: up-letsencrypt-http
up-letsencrypt-http: .init ${TEMP_COMPOSE}-letsencrypt-http prune-docker-stack-configs ## Deploys jaeger stack using let's encrypt http challenge
	@docker stack deploy --with-registry-auth --prune --compose-file ${TEMP_COMPOSE}-letsencrypt-http ${STACK_NAME}

.PHONY: up-letsencrypt-dns
up-letsencrypt-dns: .init ${TEMP_COMPOSE}-letsencrypt-dns prune-docker-stack-configs ## Deploys jaeger stack using let's encrypt dns challenge
	@docker stack deploy --with-registry-auth --prune --compose-file ${TEMP_COMPOSE}-letsencrypt-dns ${STACK_NAME}

.PHONY: up-dalco ## Deploys jaeger stack for Dalco Cluster
up-dalco: .init ${TEMP_COMPOSE}-dalco prune-docker-stack-configs
	@docker stack deploy --with-registry-auth --prune --compose-file ${TEMP_COMPOSE}-dalco ${STACK_NAME}

.PHONY: up-aws
up-aws: .init ${TEMP_COMPOSE}-aws prune-docker-stack-configs ## Deploys jaeger stack in aws
	@docker stack deploy --with-registry-auth --prune --compose-file ${TEMP_COMPOSE}-aws ${STACK_NAME}

.PHONY: up-master
up-master:  .init ${TEMP_COMPOSE}-master prune-docker-stack-configs
	@docker stack deploy --with-registry-auth --prune --compose-file ${TEMP_COMPOSE}-master ${STACK_NAME}

.PHONY: up-local
up-local: up

.PHONY: up-public
up-public: up-dalco

# Helpers -------------------------------------------------


.PHONY: ${TEMP_COMPOSE}-letsencrypt-http
${TEMP_COMPOSE}-letsencrypt-http: docker-compose.yml docker-compose.letsencrypt.http.yml .env
	@${REPO_BASE_DIR}/scripts/docker-stack-config.bash -e .env $<  docker-compose.letsencrypt.http.yml  > $@

.PHONY: ${TEMP_COMPOSE}-letsencrypt-dns
${TEMP_COMPOSE}-letsencrypt-dns: docker-compose.yml docker-compose.letsencrypt.dns.yml .env
	@${REPO_BASE_DIR}/scripts/docker-stack-config.bash -e .env $< docker-compose.letsencrypt.dns.yml  > $@

.PHONY: ${TEMP_COMPOSE}-dalco
${TEMP_COMPOSE}-dalco: docker-compose.yml .env
	@${REPO_BASE_DIR}/scripts/docker-stack-config.bash -e .env $< > $@

.PHONY: ${TEMP_COMPOSE}-master
${TEMP_COMPOSE}-master: docker-compose.yml .env
	@${REPO_BASE_DIR}/scripts/docker-stack-config.bash -e .env $< > $@


.PHONY: ${TEMP_COMPOSE}-aws
${TEMP_COMPOSE}-aws: docker-compose.yml docker-compose.aws.yml .env
	@${REPO_BASE_DIR}/scripts/docker-stack-config.bash -e .env $< docker-compose.aws.yml > $@

.PHONY: ${TEMP_COMPOSE}
${TEMP_COMPOSE}: docker-compose.yml .env
	@${REPO_BASE_DIR}/scripts/docker-stack-config.bash -e .env $<  > $@

.PHONY: jupyter_server_config.py
jupyter_server_config.py: jupyter_server_config.py.template
	@set -o allexport; \
	source $(REPO_CONFIG_LOCATION); \
	set +o allexport; \
	envsubst < $< > $@
