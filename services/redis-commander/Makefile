.DEFAULT_GOAL := help

# Internal VARIABLES ------------------------------------------------
# STACK_NAME defaults to name of the current directory. Should not to be changed if you follow GitOps operating procedures.
STACK_NAME = $(notdir $(shell pwd))
TEMP_COMPOSE=.stack.${STACK_NAME}.yaml
REPO_BASE_DIR := $(shell git rev-parse --show-toplevel)

# TARGETS --------------------------------------------------
include ${REPO_BASE_DIR}/scripts/common.Makefile

.PHONY: up ## Deploys redis stack
up: .init ${TEMP_COMPOSE} prune-docker-stack-configs
	@docker stack deploy --with-registry-auth --prune --compose-file ${TEMP_COMPOSE} ${STACK_NAME}

.PHONY: up-letsencrypt-http ## Deploys redis stack using let's encrypt http challenge
up-letsencrypt-http: .init ${TEMP_COMPOSE}-letsencrypt-http
	@docker stack deploy --with-registry-auth --prune --compose-file ${TEMP_COMPOSE}-letsencrypt-http ${STACK_NAME}

.PHONY: up-letsencrypt-dns ## Deploys redis stack using let's encrypt dns challenge
up-letsencrypt-dns: .init ${TEMP_COMPOSE}-letsencrypt-dns
	@docker stack deploy --with-registry-auth --prune --compose-file ${TEMP_COMPOSE}-letsencrypt-dns ${STACK_NAME}

.PHONY: up-dalco ## Deploys redis-commander stack for Dalco Cluster
up-dalco: up

.PHONY: up-master ## Deploys redis-commander stack for Master Cluster
up-master: up

.PHONY: up-public ## Deploys redis-commander stack for public access Cluster
up-public: up

.PHONY: up-local ## Deploys redis-commander stack for local deployment
up-local: up

.PHONY: up-aws ## Deploys redis-commander stack in aws
up-aws: up

docker-compose.yml: .env config.json
	@$(call jinja, docker-compose.yml.j2, .env, docker-compose.yml.unlinted) && \
	$(_yq) docker-compose.yml.unlinted > docker-compose.yml; \
	rm docker-compose.yml.unlinted >/dev/null 2>&1;

.PHONY: ${TEMP_COMPOSE}
${TEMP_COMPOSE}: docker-compose.yml .env
	@${REPO_BASE_DIR}/scripts/docker-stack-config.bash -e .env $< > $@

.PHONY: ${TEMP_COMPOSE}-letsencrypt-http
${TEMP_COMPOSE}-letsencrypt-http: docker-compose.yml docker-compose.letsencrypt.http.yml .env
	@${REPO_BASE_DIR}/scripts/docker-stack-config.bash -e .env $< docker-compose.letsencrypt.http.yml  > $@

.PHONY: ${TEMP_COMPOSE}-letsencrypt-dns
${TEMP_COMPOSE}-letsencrypt-dns: docker-compose.yml docker-compose.letsencrypt.dns.yml .env
	@${REPO_BASE_DIR}/scripts/docker-stack-config.bash -e .env $< docker-compose.letsencrypt.dns.yml  > $@

config.json: config.json.j2 .env venv
	# generate $@
	@$(call jinja, $<, .env, $@)
	# validate and format $@
	@cat $@ | jq > /dev/null
