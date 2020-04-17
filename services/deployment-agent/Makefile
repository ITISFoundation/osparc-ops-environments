.DEFAULT_GOAL := help
SHELL := /bin/bash

APP_NAME := deployment-agent

# External VARIABLES
include .env
# Internal VARIABLES ------------------------------------------------
# STACK_NAME defaults to name of the current directory. Should not to be changed if you follow GitOps operating procedures.
ifeq ($(PREFIX_STACK_NAME),)
STACK_NAME := $(notdir $(PWD))
else
STACK_NAME := $(PREFIX_STACK_NAME)-$(notdir $(PWD))
endif
SWARM_HOSTS = $(shell docker node ls --format={{.Hostname}} 2>/dev/null)
DOCKER_MINIO_ACCESS_KEY = $(shell docker secret inspect --format {{.Spec.Name}} minio_secret_key 2>/dev/null)
DOCKER_MINIO_SECRET_KEY = $(shell docker secret inspect --format {{.Spec.Name}} minio_access_key 2>/dev/null)

TEMP_COMPOSE = .stack.${STACK_NAME}.yaml
TEMP_COMPOSE-devel = .stack.${STACK_NAME}.devel.yml


# Network from which services are reverse-proxied
#  - by default it will create an overal attachable network called public_network
ifeq ($(public_network),)
PUBLIC_NETWORK = public-network
else
PUBLIC_NETWORK := $(public_network)
endif
export PUBLIC_NETWORK

# Network that includes all services to monitor
#  - by default it will create an overal attachable network called monitored_network
ifeq ($(monitored_network),)
MONITORED_NETWORK = monitored_network
else
MONITORED_NETWORK := $(monitored_network)
endif
export MONITORED_NETWORK



# exports
export VCS_URL:=$(shell git config --get remote.origin.url)
export VCS_REF:=$(shell git rev-parse --short HEAD)
export VCS_STATUS_CLIENT:=$(if $(shell git status -s),'modified/untracked','clean')
export BUILD_DATE:=$(shell date -u +"%Y-%m-%dT%H:%M:%SZ")

export DOCKER_REGISTRY ?= itisfoundation
export DOCKER_IMAGE_TAG ?= $(shell cat VERSION)
$(info DOCKER_REGISTRY set to ${DOCKER_REGISTRY})
$(info DOCKER_IMAGE_TAG set to ${DOCKER_IMAGE_TAG})

include $(realpath $(CURDIR)/../../scripts/common.mk)

## docker BUILD -------------------------------
.PHONY: build build-kit build-x build-devel build-devel-kit build-devel-x
build build-kit build-x build-devel build-devel-kit build-devel-x: ## Builds $(APP_NAME) image
	@$(if $(findstring -kit,$@),export DOCKER_BUILDKIT=1;export COMPOSE_DOCKER_CLI_BUILD=1;,) \
	$(if $(findstring -x,$@),docker buildx bake, docker-compose) --file docker-compose.yml $(if $(findstring -devel,$@),--file docker-compose.devel.yaml,) $(if $(findstring -x,$@),,build)


.PHONY: up
up: .init ${DEPLOYMENT_AGENT_CONFIG} ${TEMP_COMPOSE} ## Deploys or updates current stack "$(STACK_NAME)" using replicas=X (defaults to 1)
	@docker stack deploy -c ${TEMP_COMPOSE} $(STACK_NAME)

.PHONY: up-devel
up-devel: .init ${DEPLOYMENT_AGENT_CONFIG} ${TEMP_COMPOSE-devel} ## Deploys or updates current stack "$(STACK_NAME)" using replicas=X (defaults to 1)
	@docker stack deploy -c ${TEMP_COMPOSE-devel} $(STACK_NAME)

.PHONY: down
down: ## Stops and remove stack from swarm
	-docker stack rm $(STACK_NAME)
	-docker stack rm ${SIMCORE_STACK_NAME}

.PHONY: leave
leave: ## leaves swarm stopping all stacks, secrets in it
	-docker swarm leave -f

.PHONY: push
push: ## Pushes service to the registry.
	docker push ${DOCKER_REGISTRY}/$(APP_NAME):${DOCKER_IMAGE_TAG}
	docker tag ${DOCKER_REGISTRY}/$(APP_NAME):${DOCKER_IMAGE_TAG} ${DOCKER_REGISTRY}/deployment-agent:latest
	docker push ${DOCKER_REGISTRY}/$(APP_NAME):latest

.PHONY: pull
pull: ## Pulls service from the registry.
	docker pull ${DOCKER_REGISTRY}/$(APP_NAME):${DOCKER_IMAGE_TAG}

.PHONY: config
config: ${DEPLOYMENT_AGENT_CONFIG} ## Create an initial configuration file.

.PHONY: install-dev
install-dev: ## install deployment agent dev
	pip install -r requirements/dev.txt

# Testing -------------------------------------------------
.PHONY: install-test
install-test: install-dev ## install deployment agent testing facilities
	pip install -r requirements/ci.txt

.PHONY: unit-test
unit-test: install-test ## Execute unit tests
	pytest --cov-append --color=yes --cov-report=term-missing --cov-report=xml --cov=simcore_service_deployment_agent -v tests


## PYTHON -------------------------------
.PHONY: pylint

PY_PIP = $(if $(IS_WIN),cd .venv/Scripts && pip.exe,.venv/bin/pip3)

pylint: ## Runs python linter framework's wide
	# See exit codes and command line https://pylint.readthedocs.io/en/latest/user_guide/run.html#exit-codes
	# TODO: NOT windows friendly
	/bin/bash -c "pylint --jobs=0 --rcfile=.pylintrc $(strip $(shell find services packages -iname '*.py' \
											-not -path "*egg*" \
											-not -path "*migration*" \
											-not -path "*contrib*" \
											-not -path "*-sdk/python*" \
											-not -path "*generated_code*" \
											-not -path "*datcore.py" \
											-not -path "*web/server*"))"

.PHONY: devenv devenv-all

.venv:
	python3 -m venv $@
	$@/bin/pip3 install --upgrade \
		pip \
		wheel \
		setuptools

devenv: .venv ## create a python virtual environment with dev tools (e.g. linters, etc)
	$</bin/pip3 install -r requirements.txt
	@echo "To activate the venv, execute 'source .venv/bin/activate'"

# Helpers -------------------------------------------------
.PHONY: .init
.init:
	## initialize swarm cluster
	$(if $(SWARM_HOSTS),  \
		,                 \
		docker swarm init \
	)
	@$(if $(filter $(PUBLIC_NETWORK), $(shell docker network ls --format="{{.Name}}")) \
		, docker network ls --filter="name==$(PUBLIC_NETWORK)" \
		, docker network create --attachable --driver=overlay $(PUBLIC_NETWORK) \
	)
	@$(if $(filter $(MONITORED_NETWORK), $(shell docker network ls --format="{{.Name}}")) \
		, docker network ls --filter="name==$(MONITORED_NETWORK)" \
		, docker network create --attachable --driver=overlay $(MONITORED_NETWORK) \
	)

${DEPLOYMENT_AGENT_CONFIG}: deployment_config.default.yaml
	@cp $< $@


docker-compose-configs = $(wildcard docker-compose*.yml)

${TEMP_COMPOSE}: .env $(docker-compose-configs)
	@docker-compose --file docker-compose.yml config > $@

${TEMP_COMPOSE-devel}: .env $(docker-compose-configs)
	@docker-compose --file docker-compose.yml --file docker-compose.devel.yaml config > $@
