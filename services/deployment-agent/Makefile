# author: Sylvain Anderegg

VERSION := $(shell uname -a)
ifneq (,$(findstring Microsoft,$(VERSION)))
$(info    detected WSL)
export DOCKER_COMPOSE=docker-compose
export DOCKER=docker
else ifeq ($(OS), Windows_NT)
$(info    detected Powershell/CMD)
export DOCKER_COMPOSE=docker-compose.exe
export DOCKER=docker.exe
else ifneq (,$(findstring Darwin,$(VERSION)))
$(info    detected OSX)
export DOCKER_COMPOSE=docker-compose
export DOCKER=docker
else
$(info    detected native linux)
export DOCKER_COMPOSE=docker-compose
export DOCKER=docker
endif

TEMPCOMPOSE := $(shell mktemp)
SERVICES_LIST := deployment-agent

export VCS_URL:=$(shell git config --get remote.origin.url)
export VCS_REF:=$(shell git rev-parse --short HEAD)
export VCS_STATUS_CLIENT:=$(if $(shell git status -s),'modified/untracked','clean')
export BUILD_DATE:=$(shell date -u +"%Y-%m-%dT%H:%M:%SZ")

# using ?= will only set if absent
export DOCKER_IMAGE_TAG ?= $(shell cat VERSION)
$(info DOCKER_IMAGE_TAG set to ${DOCKER_IMAGE_TAG})

# default to local (no registry)
export DOCKER_REGISTRY ?= itisfoundation
$(info DOCKER_REGISTRY set to ${DOCKER_REGISTRY})


## Tools ------------------------------------------------------------------------------------------------------
#
tools =

ifeq ($(shell uname -s),Darwin)
	SED = gsed
else
	SED = sed
endif

ifeq ($(shell which ${SED}),)
	tools += $(SED)
endif


## ------------------------------------------------------------------------------------------------------
.PHONY: all
all: help info
ifdef tools
	$(error "Can't find tools:${tools}")
endif


.PHONY: build build-devel
# target: build, build-devel: – Builds all service images.
build:
	${DOCKER_COMPOSE} -f docker-compose.yml build --parallel

build-devel:
	${DOCKER_COMPOSE} -f docker-compose.yml -f docker-compose.devel.yaml build --parallel

.PHONY: up up-devel down
# target: up, up-devel, down: – Starts/Stops services.
up-devel: .env deployment_config.yaml
	${DOCKER} swarm init
	${DOCKER_COMPOSE} -f docker-compose.yml -f docker-compose.devel.yaml config > $(TEMPCOMPOSE).tmp-compose.yml
	${DOCKER} stack deploy -c $(TEMPCOMPOSE).tmp-compose.yml portainer

up: .env deployment_config.yaml
	${DOCKER} swarm init
	${DOCKER_COMPOSE} -f docker-compose.yml config > $(TEMPCOMPOSE).tmp-compose.yml ;
	${DOCKER} stack deploy -c $(TEMPCOMPOSE).tmp-compose.yml portainer

down:
	${DOCKER} swarm leave -f

.PHONY: push
# target: push: – Pushes services to the registry.
push:
	${DOCKER} push ${DOCKER_REGISTRY}/deployment-agent:${DOCKER_IMAGE_TAG}
	${DOCKER} tag ${DOCKER_REGISTRY}/deployment-agent:${DOCKER_IMAGE_TAG} ${DOCKER_REGISTRY}/deployment-agent:latest
	${DOCKER} push ${DOCKER_REGISTRY}/deployment-agent:latest

.PHONY: pull
# target: pull: – Pulls services from the registry.
pull:
	${DOCKER} pull ${DOCKER_REGISTRY}/deployment-agent:${DOCKER_IMAGE_TAG}

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

.PHONY: info
# target: info – Displays some parameters of makefile environments
info:
	@echo '+ VCS_* '
	@echo '  - ULR                : ${VCS_URL}'
	@echo '  - REF                : ${VCS_REF}'
	@echo '  - (STATUS)REF_CLIENT : (${VCS_STATUS_CLIENT})'
	@echo '+ BUILD_DATE           : ${BUILD_DATE}'
	@echo '+ VERSION              : ${VERSION}'
	@echo '+ DOCKER_REGISTRY      : ${DOCKER_REGISTRY}'
	@echo '+ DOCKER_IMAGE_TAG     : ${DOCKER_IMAGE_TAG}'


## -------------------------------
# Virtual Environments
.venv:
# target: .venv – Creates a python virtual environment with dev tools (pip, pylint, ...)
	python3 -m venv .venv
	.venv/bin/pip3 install --upgrade pip wheel setuptools
	.venv/bin/pip3 install pylint autopep8 virtualenv
	@echo "To activate the venv, execute 'source .venv/bin/activate' or '.venv/bin/activate.bat' (WIN)"

## -------------------------------
# Auxiliary targets.

.PHONY: clean
# target: clean – Cleans all unversioned files in project
clean:
	@git clean -dxf -e .vscode/


.PHONY: help
# target: help – Display all callable targets
help:
	@echo "Make targets in osparc-simcore:"
	@echo
	@egrep "^\s*#\s*target\s*:\s*" [Mm]akefile \
	| $(SED) -r "s/^\s*#\s*target\s*:\s*//g"
	@echo
