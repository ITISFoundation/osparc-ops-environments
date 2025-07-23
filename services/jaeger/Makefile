.DEFAULT_GOAL := help



# Internal VARIABLES ------------------------------------------------
# STACK_NAME defaults to name of the current directory. Should not to be changed if you follow GitOps operating procedures.
STACK_NAME = $(notdir $(shell pwd))
TEMP_COMPOSE=.stack.${STACK_NAME}.yaml
REPO_BASE_DIR := $(shell git rev-parse --show-toplevel)

# TARGETS --------------------------------------------------
include ${REPO_BASE_DIR}/scripts/common.Makefile

.PHONY: up
up: .init .env ${TEMP_COMPOSE}  ## Deploys jaeger stack
	@docker stack deploy --with-registry-auth --prune --compose-file ${TEMP_COMPOSE} ${STACK_NAME}

.PHONY: up-letsencrypt-http ## Deploys jaeger stack using let's encrypt http challenge
up-letsencrypt-http: .init .env ${TEMP_COMPOSE}-letsencrypt-http
	@docker stack deploy --with-registry-auth --prune --compose-file ${TEMP_COMPOSE}-letsencrypt-http ${STACK_NAME}

.PHONY: up-letsencrypt-dns ## Deploys jaeger stack using let's encrypt dns challenge
up-letsencrypt-dns: .init .env ${TEMP_COMPOSE}-letsencrypt-dns
	@docker stack deploy --with-registry-auth --prune --compose-file ${TEMP_COMPOSE}-letsencrypt-dns ${STACK_NAME}

.PHONY: up-dalco ## Deploys jaeger stack for Dalco Cluster
up-dalco: up

.PHONY: up-aws ## Deploys jaeger stack for aws
up-aws: .init .env ${TEMP_COMPOSE}-aws  ## Deploys jaeger stack in aws
	@docker stack deploy --with-registry-auth --prune --compose-file ${TEMP_COMPOSE}-aws ${STACK_NAME}

.PHONY: up-master ## Deploys jaeger stack for master Cluster
up-master: up

.PHONY: up-public ## Deploys jaeger stack for public acess deploy
up-public: up-dalco

.PHONY: up-local ## Deploys jaeger stack for local deployment
up-local: up

# Helpers -------------------------------------------------

docker-compose.yml: docker-compose.yml.j2 venv .env
	@$(call jinja, $<, .env, $@)

.PHONY: ${TEMP_COMPOSE}
${TEMP_COMPOSE}: docker-compose.yml
	@${REPO_BASE_DIR}/scripts/docker-stack-config.bash $< > $@

.PHONY: ${TEMP_COMPOSE}-letsencrypt-http
${TEMP_COMPOSE}-letsencrypt-http: docker-compose.yml docker-compose.letsencrypt.http.yml
	@${REPO_BASE_DIR}/scripts/docker-stack-config.bash $< docker-compose.letsencrypt.http.yml > $@

.PHONY: ${TEMP_COMPOSE}-letsencrypt-dns
${TEMP_COMPOSE}-letsencrypt-dns: docker-compose.yml docker-compose.letsencrypt.dns.yml
	@${REPO_BASE_DIR}/scripts/docker-stack-config.bash $< docker-compose.letsencrypt.dns.yml > $@

.PHONY: ${TEMP_COMPOSE}-aws
${TEMP_COMPOSE}-aws: docker-compose.yml docker-compose.aws.yml
	@${REPO_BASE_DIR}/scripts/docker-stack-config.bash $< docker-compose.aws.yml > $@
