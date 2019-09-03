.DEFAULT_GOAL := help

export VCS_URL:=$(shell git config --get remote.origin.url)
export VCS_REF:=$(shell git rev-parse --short HEAD)
export VCS_STATUS_CLIENT:=$(if $(shell git status -s),'modified/untracked','clean')
export BUILD_DATE:=$(shell date -u +"%Y-%m-%dT%H:%M:%SZ")

export DOCKER_REGISTRY ?= itisfoundation
export DOCKER_IMAGE_TAG ?= $(shell cat VERSION)
$(info DOCKER_REGISTRY set to ${DOCKER_REGISTRY})
$(info DOCKER_IMAGE_TAG set to ${DOCKER_IMAGE_TAG})

# STACK_NAME defaults to name of the current directory. Should not to be changed if you follow GitOps operating procedures.
STACK_NAME = $(notdir $(PWD))
SWARM_HOSTS = $(shell docker node ls --format={{.Hostname}} 2>/dev/null)
TEMPCOMPOSE := $(shell mktemp)

.PHONY: help
help:  ## Display this help
	@awk 'BEGIN {FS = ":.*##"; printf "\nUsage:\n  make \033[36m<target>\033[0m\n\nTargets:\n"} /^[a-zA-Z_-]+:.*?##/ { printf "  \033[36m%-10s\033[0m %s\n", $$1, $$2 }' $(MAKEFILE_LIST)

.PHONY: info ## Displays some parameters of makefile environments
info:
	@echo '+ VCS_* '
	@echo '  - URL                : ${VCS_URL}'
	@echo '  - REF                : ${VCS_REF}'
	@echo '  - (STATUS)REF_CLIENT : (${VCS_STATUS_CLIENT})'
	@echo '+ BUILD_DATE           : ${BUILD_DATE}'
	@echo '+ DOCKER_REGISTRY      : ${DOCKER_REGISTRY}'
	@echo '+ DOCKER_IMAGE_TAG     : ${DOCKER_IMAGE_TAG}'

.PHONY: init
init: ## initialize swarm cluster
	$(if $(SWARM_HOSTS),  \
		,                 \
		docker swarm init \
	)

.PHONY: build build-devel
build: ## Builds all service images.
	docker-compose -f docker-compose.yml build --parallel

build-devel: ## Builds all service images in development mode.
	docker-compose -f docker-compose.yml -f docker-compose.devel.yaml build --parallel

.PHONY: up up-devel
up-devel: init .env deployment_config.yaml ## Starts services in development mode.
	docker-compose -f docker-compose.yml -f docker-compose.devel.yaml config > $(TEMPCOMPOSE).tmp-compose.yml
	docker stack deploy -c $(TEMPCOMPOSE).tmp-compose.yml ${STACK_NAME}

up: init .env deployment_config.yaml ## Starts services.
	docker-compose -f docker-compose.yml config > $(TEMPCOMPOSE).tmp-compose.yml ;
	docker stack deploy -c $(TEMPCOMPOSE).tmp-compose.yml ${STACK_NAME}

.PHONY: down reset
down: ## Stops services
	docker stack rm ${STACK_NAME}

reset: ## Leaves swarm stopping all services in it.
	-docker swarm leave -f

.PHONY: push
push: ## Pushes service to the registry.
	docker push ${DOCKER_REGISTRY}/deployment-agent:${DOCKER_IMAGE_TAG}
	docker tag ${DOCKER_REGISTRY}/deployment-agent:${DOCKER_IMAGE_TAG} ${DOCKER_REGISTRY}/deployment-agent:latest
	docker push ${DOCKER_REGISTRY}/deployment-agent:latest

.PHONY: pull
pull: ## Pulls service from the registry.
	docker pull ${DOCKER_REGISTRY}/deployment-agent:${DOCKER_IMAGE_TAG}

# basic checks -------------------------------------
.env: .env-devel
	# first check if file exists, copies it
	@if [ ! -f $@ ]	; then \
		echo "##### $@ does not exist, copying $< ############"; \
		cp $< $@; \
	else \
		echo "#####  $< is newer than $@ ####"; \
		diff -uN $@ $<; \
		false; \
	fi

deployment_config.yaml:
	@echo "deployment_config.yaml file is missing! Copying from tests folder..."
	cp tests/test-config.yaml deployment_config.yaml;



## -------------------------------
# Virtual Environments
venv: .venv ## Creates a python virtual environment with dev tools (pip, pylint, ...)
.venv:
	python3 -m venv .venv
	.venv/bin/pip3 install --upgrade pip wheel setuptools
	.venv/bin/pip3 install pylint autopep8 virtualenv
	@echo "To activate the venv, execute 'source .venv/bin/activate' or '.venv/bin/activate.bat' (WIN)"

## -------------------------------
# Auxiliary targets.

.PHONY: clean
clean: ## Cleans all unversioned files in project.
	@git clean -dxf -e .vscode/


