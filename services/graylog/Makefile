.DEFAULT_GOAL := help


# Internal VARIABLES ------------------------------------------------
# STACK_NAME defaults to name of the current directory. Should not to be changed if you follow GitOps operating procedures.
STACK_NAME = $(notdir $(shell pwd))
TEMP_COMPOSE=.stack.${STACK_NAME}.yaml
REPO_BASE_DIR := $(shell git rev-parse --show-toplevel)

# TARGETS --------------------------------------------------
include ${REPO_BASE_DIR}/scripts/common.Makefile

.PHONY: up
up: .init .env ${TEMP_COMPOSE}  ## Deploys graylog stack
	@docker stack deploy --with-registry-auth --prune --compose-file ${TEMP_COMPOSE} ${STACK_NAME}
	$(MAKE) configure

.PHONY: up-letsencrypt-http ## Deploys graylog stack using let's encrypt http challenge
up-letsencrypt-http: .init .env ${TEMP_COMPOSE}-letsencrypt-http
	@docker stack deploy --with-registry-auth --prune --compose-file ${TEMP_COMPOSE}-letsencrypt-http ${STACK_NAME}

.PHONY: up-letsencrypt-dns ## Deploys graylog stack using let's encrypt dns challenge
up-letsencrypt-dns: .init .env ${TEMP_COMPOSE}-letsencrypt-dns
	@docker stack deploy --with-registry-auth --prune --compose-file ${TEMP_COMPOSE}-letsencrypt-dns ${STACK_NAME}

.PHONY: up-dalco ## Deploys graylog stack for Dalco Cluster
up-dalco: .init .env ${TEMP_COMPOSE}-dalco
	@docker stack deploy --with-registry-auth --prune --compose-file ${TEMP_COMPOSE}-dalco ${STACK_NAME}
	$(MAKE) configure

.PHONY: up-public  ## Deploys graylog stack for public access Cluster
up-public: up-dalco

.PHONY: up-aws  ## Deploys graylog stack for aws
up-aws: .init .env ${TEMP_COMPOSE}-aws  ## Deploys graylog stack using let's encrypt
	@docker stack deploy --with-registry-auth --prune --compose-file ${TEMP_COMPOSE}-aws ${STACK_NAME}
	$(MAKE) configure

.PHONY: up-master ## Deploys graylog stack for master Cluster
up-master: .init .env ${TEMP_COMPOSE}-master
	@docker stack deploy --with-registry-auth --prune --compose-file ${TEMP_COMPOSE}-master ${STACK_NAME}
	$(MAKE) configure

.PHONY: up-local ## Deploys graylog stack for local deployment
up-local: .init .env ${TEMP_COMPOSE}-local  ## Deploys graylog stack for local cluster
	@docker stack deploy --with-registry-auth --prune --compose-file ${TEMP_COMPOSE}-local ${STACK_NAME}
	$(MAKE) configure

# Helpers -------------------------------------------------

.PHONY: ${TEMP_COMPOSE}
${TEMP_COMPOSE}: docker-compose.yml ## Deploys stack
# Hacky workaround introduced by DK2021 via https://github.com/docker/compose/issues/7771
	@${REPO_BASE_DIR}/scripts/docker-compose-config.bash -e .env $< > $@

.PHONY: ${TEMP_COMPOSE}-letsencrypt-http ## Deploys stack using let's encrypt http challenge
${TEMP_COMPOSE}-letsencrypt-http: docker-compose.yml docker-compose.letsencrypt.http.yml
	@${REPO_BASE_DIR}/scripts/docker-compose-config.bash -e .env $< docker-compose.letsencrypt.http.yml > $@

.PHONY: ${TEMP_COMPOSE}-letsencrypt-dns ## Deploys stack using let's encrypt dns challenge
${TEMP_COMPOSE}-letsencrypt-dns: docker-compose.yml docker-compose.letsencrypt.dns.yml
	@${REPO_BASE_DIR}/scripts/docker-compose-config.bash -e .env $< docker-compose.letsencrypt.dns.yml > $@

.PHONY: ${TEMP_COMPOSE}-dalco
${TEMP_COMPOSE}-dalco: docker-compose.yml docker-compose.dalco.yml
	@${REPO_BASE_DIR}/scripts/docker-compose-config.bash -e .env $< docker-compose.dalco.yml > $@

.PHONY: ${TEMP_COMPOSE}-master .env ## Deploys stack on master deployment
# Hacky workaround introduced by DK2021 via https://github.com/docker/compose/issues/7771
${TEMP_COMPOSE}-master: docker-compose.yml docker-compose.master.yml
	@${REPO_BASE_DIR}/scripts/docker-compose-config.bash -e .env $< docker-compose.master.yml > $@

.PHONY: ${TEMP_COMPOSE}-local ## Deploys stack on local deployment
# Hacky workaround introduced by DK2021 via https://github.com/docker/compose/issues/7771
${TEMP_COMPOSE}-local: docker-compose.yml docker-compose.local.yml
	@${REPO_BASE_DIR}/scripts/docker-compose-config.bash -e .env $< docker-compose.local.yml > $@

.PHONY: ${TEMP_COMPOSE}-aws ## Deploys stack on aws
${TEMP_COMPOSE}-aws: docker-compose.yml docker-compose.letsencrypt.dns.yml docker-compose.aws.yml
	@${REPO_BASE_DIR}/scripts/docker-compose-config.bash -e .env $< docker-compose.aws.yml docker-compose.letsencrypt.dns.yml  > $@

.PHONY: .env
.env: template.env $(REPO_CONFIG_LOCATION)
	@set -o allexport; \
	source $(REPO_CONFIG_LOCATION); \
	GRAYLOG_ROOT_PASSWORD_SHA2=$$(echo -n "$${GRAYLOG_ROOT_PASSWORD}" | sha256sum | cut -d ' ' -f1);\
	export GRAYLOG_ROOT_PASSWORD_SHA2;\
	GRAYLOG_PASSWORD_SECRET=$$(tr -dc A-Za-z0-9 </dev/urandom | head -c 16 ; echo '');\
	export GRAYLOG_PASSWORD_SECRET;\
	set +o allexport; \
	envsubst < $< > $@


.PHONY: configure
configure: .env ## Test is Graylog is online and configure Graylog inputs
	@cd scripts;\
	if [ ! -d ".venv" ]; \
	then\
		python3 -m venv .venv;\
	fi;\
	source .venv/bin/activate;\
	pip install -r requirements.txt > /dev/null 2>&1;\
	set -o allexport; \
	source ../$<;\
	set +o allexport; \
	envsubst < alerts.template.yaml > alerts.yaml;\
	python configure.py;
