.DEFAULT_GOAL := help


# Internal VARIABLES ------------------------------------------------
# STACK_NAME defaults to name of the current directory. Should not to be changed if you follow GitOps operating procedures.
STACK_NAME = $(notdir $(shell pwd))
TEMP_COMPOSE=.stack.${STACK_NAME}.yaml
REPO_BASE_DIR := $(shell git rev-parse --show-toplevel)

# TARGETS --------------------------------------------------
include ${REPO_BASE_DIR}/scripts/common.Makefile
include $(REPO_CONFIG_LOCATION)

.PHONY: up ## Deploys pg-backup stack
up: .init .env ${TEMP_COMPOSE}  ## Deploys pg-backup stack
	docker stack deploy --with-registry-auth --compose-file ${TEMP_COMPOSE} ${PREFIX_STACK_NAME}-${STACK_NAME}

.PHONY: up-dalco ## Deploys pg-backup stack for Dalco Cluster
up-dalco: up

.PHONY: up-local ## Deploys pg-backup stack for local deployment
up-local: up

.PHONY: up-master ## Deploys pg-backup stack for Master Cluster
up-master: up-dalco

.PHONY: up-public ## Deploys pg-backup stack for public access cluster
up-public: up

# Helpers -------------------------------------------------

.PHONY: ${TEMP_COMPOSE}
${TEMP_COMPOSE}: docker-compose.yml .venv .env
	${REPO_BASE_DIR}/scripts/docker-stack-config.bash -e .env $< > $@

.venv:
	# creating virtual environment with tooling (jinja, etc)
	@python3 -m venv .venv
	@.venv/bin/pip3 install --upgrade pip wheel setuptools
	@.venv/bin/pip3 install jinja2 j2cli[yaml]

define jinja
	.venv/bin/j2 --format=env $(1) .env -o $(2)
endef
