.DEFAULT_GOAL := help



# Internal VARIABLES ------------------------------------------------
# STACK_NAME defaults to name of the current directory. Should not to be changed if you follow GitOps operating procedures.
STACK_NAME = $(notdir $(shell pwd))
TEMP_COMPOSE=.stack.${STACK_NAME}.yaml
REPO_BASE_DIR := $(shell git rev-parse --show-toplevel)

# TARGETS --------------------------------------------------
include ${REPO_BASE_DIR}/scripts/common.Makefile

.PHONY: up ## Deploys stack
up: .init .env ${TEMP_COMPOSE} filestash_config.json
	@docker stack deploy --with-registry-auth --prune --compose-file ${TEMP_COMPOSE} ${STACK_NAME}

.PHONY: up-letsencrypt-http ## Deploys stack using let's encrypt http challenge
up-letsencrypt-http: .init .env filestash_config.json ${TEMP_COMPOSE}-letsencrypt-http
	@docker stack deploy --with-registry-auth --prune --compose-file ${TEMP_COMPOSE}-letsencrypt-http ${STACK_NAME}

.PHONY: up-letsencrypt-dns ## Deploys stack using let's encrypt dns challenge
up-letsencrypt-dns: .init .env filestash_config.json ${TEMP_COMPOSE}-letsencrypt-dns
	@docker stack deploy --with-registry-auth --prune --compose-file ${TEMP_COMPOSE}-letsencrypt-dns ${STACK_NAME}

.PHONY: up-dalco ## Deploys stack for Dalco Cluster
up-dalco: .init .env filestash_config.json ${TEMP_COMPOSE}-dalco
	@docker stack deploy --with-registry-auth --prune --compose-file ${TEMP_COMPOSE}-dalco ${STACK_NAME}

.PHONY: up-aws ## Deploys stack on aws
up-aws: .init .env ${TEMP_COMPOSE}-aws filestash_config.json ## Deploys stack in aws
	@docker stack deploy --with-registry-auth --prune --compose-file ${TEMP_COMPOSE}-aws ${STACK_NAME}

.PHONY: up-master ## Deploys stack for master Cluster
up-master: .init .env filestash_config.json ${TEMP_COMPOSE}-master
	@docker stack deploy --with-registry-auth --prune --compose-file ${TEMP_COMPOSE}-master ${STACK_NAME}

.PHONY: up-public ## Deploys stack on public
up-public: up-dalco

.PHONY: up-local ## Deploys stack on local deployment
up-local: up

# Helpers -------------------------------------------------

.PHONY: ${TEMP_COMPOSE}
${TEMP_COMPOSE}: docker-compose.yml
	@${REPO_BASE_DIR}/scripts/docker-compose-config.bash -e .env $< > $@

.PHONY: ${TEMP_COMPOSE}-letsencrypt-http
${TEMP_COMPOSE}-letsencrypt-http: docker-compose.yml docker-compose.letsencrypt.http.yml
	@${REPO_BASE_DIR}/scripts/docker-compose-config.bash -e .env $< docker-compose.letsencrypt.http.yml  > $@

.PHONY: ${TEMP_COMPOSE}-letsencrypt-dns
${TEMP_COMPOSE}-letsencrypt-dns: docker-compose.yml docker-compose.letsencrypt.dns.yml
	@${REPO_BASE_DIR}/scripts/docker-compose-config.bash -e .env $< docker-compose.letsencrypt.dns.yml  > $@

.PHONY: ${TEMP_COMPOSE}-dalco
${TEMP_COMPOSE}-dalco: docker-compose.yml docker-compose.dalco.yml
	@${REPO_BASE_DIR}/scripts/docker-compose-config.bash -e .env $< docker-compose.dalco.yml  > $@

.PHONY: ${TEMP_COMPOSE}-master
${TEMP_COMPOSE}-master: docker-compose.yml docker-compose.master.yml
	@${REPO_BASE_DIR}/scripts/docker-compose-config.bash -e .env $< docker-compose.master.yml  > $@

.PHONY: ${TEMP_COMPOSE}-aws
${TEMP_COMPOSE}-aws: docker-compose.yml docker-compose.letsencrypt.dns.yml docker-compose.aws.yml
	@${REPO_BASE_DIR}/scripts/docker-compose-config.bash -e .env $< docker-compose.aws.yml docker-compose.letsencrypt.dns.yml  > $@


filestash_config.json: .env
	@set -o allexport; \
	source $(REPO_CONFIG_LOCATION); \
	if [ ! -d "venv" ]; \
	then\
		python3 -m venv venv;\
	fi;\
	source venv/bin/activate;\
	pip install -r requirements.txt > /dev/null 2>&1;\
	python create_config.py;\
	deactivate;
