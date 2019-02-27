# author: Sylvain Anderegg

# TODO: add flavours by combinging docker-compose files. Namely development, test and production.
VERSION := $(shell uname -a)
# SAN this is a hack so that docker-compose works in the linux virtual environment under Windows
WINDOWS_MODE=OFF
ifneq (,$(findstring Microsoft,$(VERSION)))
$(info    detected WSL)
export DOCKER_COMPOSE=docker-compose
export DOCKER=docker
export RUN_DOCKER_ENGINE_ROOT=1
# Windows does not have these things defined... but they are needed to execute a local swarm
export DOCKER_GID=1042
export HOST_GID=1000
WINDOWS_MODE=ON
else ifeq ($(OS), Windows_NT)
$(info    detected Powershell/CMD)
export DOCKER_COMPOSE=docker-compose.exe
export DOCKER=docker.exe
export RUN_DOCKER_ENGINE_ROOT=1
export DOCKER_GID=1042
export HOST_GID=1000
WINDOWS_MODE=ON
else ifneq (,$(findstring Darwin,$(VERSION)))
$(info    detected OSX)
export DOCKER_COMPOSE=docker-compose
export DOCKER=docker
export RUN_DOCKER_ENGINE_ROOT=1
export DOCKER_GID=1042
export HOST_GID=1000
else
$(info    detected native linux)
export DOCKER_COMPOSE=docker-compose
export DOCKER=docker
export RUN_DOCKER_ENGINE_ROOT=0
export DOCKER_GID=1042
export HOST_GID=1000
# TODO: Add a meaningfull call to retrieve the local docker group ID and the user ID in linux.
endif

TEMPCOMPOSE := $(shell mktemp)

.venv:
# target: .venv – Creates a python virtual environment with dev tools (pip, pylint, ...)
	python3 -m venv .venv
	.venv/bin/pip3 install --upgrade pip wheel setuptools
	.venv/bin/pip3 install pylint autopep8 virtualenv
	@echo "To activate the venv, execute 'source .venv/bin/activate' or '.venv/bin/activate.bat' (WIN)"


clean:
	@git clean -dxf -e .vscode/

build-devel:
	${DOCKER_COMPOSE} -f docker-compose.yml -f docker-compose.devel.yaml build --parallel

up-devel: .env deployment_config.yaml
	${DOCKER} swarm init
	${DOCKER_COMPOSE} -f docker-compose.yml -f docker-compose.devel.yaml config > $(TEMPCOMPOSE).tmp-compose.yml
	${DOCKER} stack deploy -c $(TEMPCOMPOSE).tmp-compose.yml portainer

build:
	${DOCKER_COMPOSE} -f docker-compose.yml build --parallel

up: .env deployment_config.yaml
	${DOCKER} swarm init
	${DOCKER_COMPOSE} -f docker-compose.yml config > $(TEMPCOMPOSE).tmp-compose.yml ;
	${DOCKER} stack deploy -c $(TEMPCOMPOSE).tmp-compose.yml portainer

down:
	${DOCKER} swarm leave -f

push:
	${DOCKER} login ${DOCKER_REGISTRY}
	${DOCKER} tag deployment-agent:latest ${DOCKER_REGISTRY}/deployment-agent:${SERVICES_VERSION}
	${DOCKER} push ${DOCKER_REGISTRY}/deployment-agent:${SERVICES_VERSION}

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
	cp deployment-agent/tests/test-config.yaml deployment_config.yaml;
