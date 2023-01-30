.DEFAULT_GOAL := help

# Internal VARIABLES ------------------------------------------------
# STACK_NAME defaults to name of the current directory. Should not to be changed if you follow GitOps operating procedures.
STACK_NAME = $(notdir $(shell pwd))
SWARM_HOSTS = $(shell docker node ls --format={{.Hostname}} 2>/dev/null)
TEMP_COMPOSE=.stack.${STACK_NAME}.yaml
REPO_BASE_DIR := $(shell git rev-parse --show-toplevel)

# TARGETS --------------------------------------------------
include ${REPO_BASE_DIR}/scripts/common.Makefile

# Helpers -------------------------------------------------
.venv:
	# creating virtual environment with tooling (jinja, etc)
	@python3 -m venv .venv
	@.venv/bin/pip3 install --upgrade pip wheel setuptools
	@.venv/bin/pip3 install jinja2 j2cli[yaml]

define jinja
	.venv/bin/j2 --format=env $(1) .env -o $(2)
endef

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

.PHONY: ${TEMP_COMPOSE}-local
${TEMP_COMPOSE}-local: docker-compose.yml docker-compose.local.yml .env
	@set -o allexport; \
	source .env; \
	set +o allexport; \
	docker-compose -f $< -f docker-compose.local.yml --log-level=ERROR config | sed -E "s/cpus: ([0-9\\.]+)/cpus: '\\1'/" > $@

.PHONY: ${TEMP_COMPOSE}-letsencrypt-http
${TEMP_COMPOSE}-letsencrypt-http: docker-compose.yml docker-compose.letsencrypt.http.yml
	@set -o allexport; \
	source .env; \
	set +o allexport; \
	docker-compose -f $< -f docker-compose.letsencrypt.http.yml --log-level=ERROR config | sed -E "s/cpus: ([0-9\\.]+)/cpus: '\\1'/" > $@

.PHONY: ${TEMP_COMPOSE}-letsencrypt-dns
${TEMP_COMPOSE}-letsencrypt-dns: docker-compose.yml docker-compose.letsencrypt.dns.yml
	@set -o allexport; \
	source .env; \
	set +o allexport; \
	docker-compose -f $< -f docker-compose.letsencrypt.dns.yml --log-level=ERROR config | sed -E "s/cpus: ([0-9\\.]+)/cpus: '\\1'/" > $@

.PHONY: ${TEMP_COMPOSE}-aws
${TEMP_COMPOSE}-aws: docker-compose.yml docker-compose.aws.yml docker-compose.letsencrypt.dns.yml
	@set -o allexport; \
	source .env; \
	set +o allexport; \
	docker-compose --file $< --file docker-compose.aws.yml --file docker-compose.letsencrypt.dns.yml --log-level=ERROR config | sed -E "s/cpus: ([0-9\\.]+)/cpus: '\\1'/" > $@

.PHONY: ${TEMP_COMPOSE}-dalco
${TEMP_COMPOSE}-dalco: docker-compose.yml docker-compose.dalco.yml docker-compose.letsencrypt.dns.yml
	@set -o allexport; \
	source .env; \
	set +o allexport; \
	docker-compose -f $< --file docker-compose.dalco.yml --file docker-compose.letsencrypt.dns.yml --log-level=ERROR config | sed -E "s/cpus: ([0-9\\.]+)/cpus: '\\1'/" > $@

.PHONY: ${TEMP_COMPOSE}-public
${TEMP_COMPOSE}-public: docker-compose.yml docker-compose.public.yml docker-compose.letsencrypt.dns.yml
	@set -o allexport; \
	source .env; \
	set +o allexport; \
	docker-compose -f $< -f docker-compose.public.yml --log-level=ERROR config | sed -E "s/cpus: ([0-9\\.]+)/cpus: '\\1'/" > $@

.PHONY: ${TEMP_COMPOSE}-master
${TEMP_COMPOSE}-master: docker-compose.yml docker-compose.master.yml docker-compose.letsencrypt.dns.yml
	@set -o allexport; \
	source .env; \
	set +o allexport; \
	docker-compose --file $< --file docker-compose.master.yml --file docker-compose.letsencrypt.dns.yml --log-level=ERROR config | sed -E "s/cpus: ([0-9\\.]+)/cpus: '\\1'/" > $@

.PHONY: docker-compose.letsencrypt.dns.yml
docker-compose.letsencrypt.dns.yml: .venv .env
	@$(call jinja, docker-compose.letsencrypt.dns.yml.j2, docker-compose.letsencrypt.dns.yml.unlinted) && \
	$(_yq) docker-compose.letsencrypt.dns.yml.unlinted > docker-compose.letsencrypt.dns.yml; \
	rm docker-compose.letsencrypt.dns.yml.unlinted >/dev/null 2>&1;

.PHONY: docker-compose.yml
docker-compose.yml: .venv .env
	@$(call jinja, docker-compose.yml.j2, docker-compose.yml.unlinted) && \
	$(_yq) docker-compose.yml.unlinted > docker-compose.yml; \
	rm docker-compose.yml.unlinted >/dev/null 2>&1;

.PHONY: .create_secrets
.create_secrets: $(REPO_BASE_DIR)/certificates/domain.crt $(REPO_BASE_DIR)/certificates/domain.key $(REPO_BASE_DIR)/certificates/rootca.crt
	@if [[ ! $$(docker secret ls | grep -w domain.crt) ]]; then docker secret create domain.crt $(REPO_BASE_DIR)/certificates/domain.crt; fi;
	@if [[ ! $$(docker secret ls | grep -w domain.key) ]]; then docker secret create domain.key $(REPO_BASE_DIR)/certificates/domain.key; fi;
	@if [[ ! $$(docker secret ls | grep -w rootca.crt) ]]; then if [ ! -f $(REPO_BASE_DIR)/certificates/rootca.crt ]; then cp $(REPO_BASE_DIR)/certificates/domain.crt $(REPO_BASE_DIR)/certificates/rootca.crt; fi; docker secret create rootca.crt $(REPO_BASE_DIR)/certificates/rootca.crt; fi;
	@if [[ ! $$(docker secret ls | grep -w storageca.crt) ]]; then if [ ! -f $(REPO_BASE_DIR)/certificates/rootca.crt ]; then cp $(REPO_BASE_DIR)/certificates/domain.crt $(REPO_BASE_DIR)/certificates/rootca.crt; fi; docker secret create storageca.crt $(REPO_BASE_DIR)/certificates/rootca.crt; fi;
