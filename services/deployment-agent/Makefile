.DEFAULT_GOAL := help
PREDEFINED_VARIABLES := $(.VARIABLES)

# If you see pwd_unknown showing up, this is why. Re-calibrate your system.
PWD ?= pwd_unknown
# Internal VARIABLES ------------------------------------------------
# STACK_NAME defaults to name of the current directory. Should not to be changed if you follow GitOps operating procedures.
STACK_NAME = $(notdir $(PWD))
SWARM_HOSTS = $(shell docker node ls --format={{.Hostname}} 2>/dev/null)
DOCKER_MINIO_ACCESS_KEY = $(shell docker secret inspect --format {{.Spec.Name}} minio_secret_key 2>/dev/null)
DOCKER_MINIO_SECRET_KEY = $(shell docker secret inspect --format {{.Spec.Name}} minio_access_key 2>/dev/null)
TEMP_COMPOSE = .stack.${STACK_NAME}.yaml
TEMP_COMPOSE-devel = .stack.${STACK_NAME}.devel.yml

# External VARIABLES
$(if $(wildcard .env), , $(shell cp .env.config .env))
include .env

# exports
export VCS_URL:=$(shell git config --get remote.origin.url)
export VCS_REF:=$(shell git rev-parse --short HEAD)
export VCS_STATUS_CLIENT:=$(if $(shell git status -s),'modified/untracked','clean')
export BUILD_DATE:=$(shell date -u +"%Y-%m-%dT%H:%M:%SZ")
export DOCKER_REGISTRY ?= itisfoundation
export DOCKER_IMAGE_TAG ?= $(shell cat VERSION)
$(info DOCKER_REGISTRY set to ${DOCKER_REGISTRY})
$(info DOCKER_IMAGE_TAG set to ${DOCKER_IMAGE_TAG})
export MINIO_HOSTNAME ?= $(shell hostname -I | cut -d ' ' -f1)
$(info MINIO_HOSTNAME set to ${MINIO_HOSTNAME})
# TARGETS --------------------------------------------------
.PHONY: help
help: ## This colourful help
	@awk 'BEGIN {FS = ":.*?## "} /^[a-zA-Z_-]+:.*?## / {printf "\033[36m%-20s\033[0m %s\n", $$1, $$2}' $(MAKEFILE_LIST)

.PHONY: up
up: .init ${DEPLOYMENT_AGENT_CONFIG} ${TEMP_COMPOSE} ## Deploys or updates current stack "$(STACK_NAME)" using replicas=X (defaults to 1)
	@docker stack deploy -c ${TEMP_COMPOSE} $(STACK_NAME)

.PHONY: up-devel
up-devel: .init .env ${DEPLOYMENT_AGENT_CONFIG} ${TEMP_COMPOSE-devel} ## Deploys or updates current stack "$(STACK_NAME)" using replicas=X (defaults to 1)
	@docker stack deploy -c ${TEMP_COMPOSE-devel} $(STACK_NAME)

.PHONY: down
down: ## Stops and remove stack from swarm
	-docker stack rm $(STACK_NAME)
	-docker stack rm ${SIMCORE_STACK_NAME}

.PHONY: leave
leave: ## leaves swarm stopping all stacks, secrets in it
	-docker swarm leave -f

.PHONY: clean
clean: ## Cleans unversioned files
	@git clean -dxf

.PHONY: info
info: ## expands all variables and relevant info on stack
	$(info VARIABLES ------------)
	$(foreach v,                                                                           \
		$(filter-out $(PREDEFINED_VARIABLES) PREDEFINED_VARIABLES, $(sort $(.VARIABLES))), \
		$(info $(v)=$($(v)))                                                               \
	)
	@echo ""
	docker ps
ifneq ($(SWARM_HOSTS), )
	@echo ""
	docker stack ls
	@echo ""
	-docker stack ps $(STACK_NAME)
	@echo ""
	-docker stack services $(STACK_NAME)
	@echo ""
	docker network ls
endif

.PHONY: build
build: ## Builds all service images.
	docker-compose -f docker-compose.yml build --parallel

.PHONY: build-devel
build-devel: ## Builds all service images in development mode.
	docker-compose -f docker-compose.yml -f docker-compose.devel.yaml build --parallel

.PHONY: push
push: ## Pushes service to the registry.
	docker push ${DOCKER_REGISTRY}/deployment-agent:${DOCKER_IMAGE_TAG}
	docker tag ${DOCKER_REGISTRY}/deployment-agent:${DOCKER_IMAGE_TAG} ${DOCKER_REGISTRY}/deployment-agent:latest
	docker push ${DOCKER_REGISTRY}/deployment-agent:latest

.PHONY: pull
pull: ## Pulls service from the registry.
	docker pull ${DOCKER_REGISTRY}/deployment-agent:${DOCKER_IMAGE_TAG}

.PHONY: config
config: ${DEPLOYMENT_AGENT_CONFIG} ## Create an initial configuration file.


# Helpers -------------------------------------------------
.PHONY: .init
.init:
	## initialize swarm cluster
	$(if $(SWARM_HOSTS),  \
		,                 \
		docker swarm init \
	)

${DEPLOYMENT_AGENT_CONFIG}: deployment_config.default.yaml
	@echo "$@ file is missing! Copying from tests folder..."
	cp $< $@

.PHONY: ${TEMP_COMPOSE}
${TEMP_COMPOSE}: docker-compose.yml
	@docker-compose -f $< config > $@
	@echo "${STACK_NAME} stack file created for in $@"

${TEMP_COMPOSE-devel}: docker-compose.yml docker-compose.devel.yml
	@docker-compose -f $< -f docker-compose.devel.yml config > $@
	@echo "${STACK_NAME} stack file created for in $@"
