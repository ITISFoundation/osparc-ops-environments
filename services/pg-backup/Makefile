.DEFAULT_GOAL := help


# Internal VARIABLES ------------------------------------------------
# STACK_NAME defaults to name of the current directory. Should not to be changed if you follow GitOps operating procedures.
STACK_NAME = $(notdir $(shell pwd))
SWARM_HOSTS = $(shell docker node ls --format={{.Hostname}} 2>/dev/null)
TEMP_COMPOSE=.stack.${STACK_NAME}.yaml
REPO_BASE_DIR := $(shell git rev-parse --show-toplevel)

# TARGETS --------------------------------------------------
include ${REPO_BASE_DIR}/scripts/common.Makefile

.PHONY: up ## Deploys pg-backup stack
up: .init .env ${TEMP_COMPOSE}  ## Deploys pg-backup stack
	docker stack deploy --with-registry-auth --prune --compose-file ${TEMP_COMPOSE} ${STACK_NAME}

.PHONY: up-dalco ## Deploys pg-backup stack for Dalco Cluster
up-dalco: up

.PHONY: up-local ## Deploys pg-backup stack for local deployment
up-local: up

.PHONY: up-master ## Deploys pg-backup stack for Master Cluster
up-master: up-dalco

.PHONY: up-public ## Deploys pg-backup stack for public access cluster
up-public: .init ${TEMP_COMPOSE}-public
	docker stack deploy --with-registry-auth --prune --compose-file ${TEMP_COMPOSE}-public ${STACK_NAME}

# Helpers -------------------------------------------------

.PHONY: ${TEMP_COMPOSE}
${TEMP_COMPOSE}: .venv  docker-compose.yml
	@$(call jinja, docker-compose.yml.j2, docker-compose.yml)
	docker-compose -f docker-compose.yml --log-level=ERROR config > $@
	rm docker-compose.yml >/dev/null 2>&1;


.PHONY: ${TEMP_COMPOSE}-public
${TEMP_COMPOSE}-public: venv  docker-compose.yml docker-compose.public.yml
	@$(call jinja, docker-compose.yml.j2, docker-compose.yml)
	docker-compose -f docker-compose.yml -f docker-compose.public.yml --log-level=ERROR config > $@
	rm docker-compose.yml >/dev/null 2>&1;

.venv:
	# creating virtual environment with tooling (jinja, etc)
	@python3 -m venv .venv
	@.venv/bin/pip3 install --upgrade pip wheel setuptools
	@.venv/bin/pip3 install jinja2 j2cli[yaml]

define jinja
	.venv/bin/j2 --format=env $(1) .env -o $(2)
endef
