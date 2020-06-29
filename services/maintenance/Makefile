# STACK_NAME defaults to name of the current directory. Should not to be changed if you follow GitOps operating procedures.
STACK_NAME = $(notdir $(PWD))

# all services
STACK_SERVICES = $(strip $(shell docker-compose config --services))

# Name of the network where simcore stack is deployed
SIMCORE_NETWORK := simcore_default

# version control
export VCS_URL          := $(shell git config --get remote.origin.url)
export VCS_REF          := $(shell git rev-parse --short HEAD)

# image
export BUILD_DATE       := $(shell date -u +"%Y-%m-%dT%H:%M:%SZ")
export DOCKER_IMAGE_TAG ?= latest
export DOCKER_REGISTRY  ?= itisfoundation

# VARIABLES
$(if $(wildcard .env), , $(shell cp env.cfg .env))
include .env


# TARGETS --------------------------------------------------
include $(realpath $(CURDIR)/../../scripts/common.Makefile)

SWARM_HOSTS = $(shell docker node ls --format={{.Hostname}} 2>/dev/null)


# Build image --

.PHONY: build
build: jupyter-diagnostics/Dockerfile ## builds services
	docker-compose build


# Registry ---

.PHONY: push
push: ## Tags and pushes built images to registry
	$(foreach service_name, \
		$(STACK_SERVICES), \
		docker push $(DOCKER_REGISTRY)/$(service_name):$(DOCKER_IMAGE_TAG) && \
		docker tag $(DOCKER_REGISTRY)/$(service_name):$(DOCKER_IMAGE_TAG) $(DOCKER_REGISTRY)/$(service_name):latest && \
		docker push $(DOCKER_REGISTRY)/$(service_name):latest \
	)

.PHONY: pull
pull: ## Pulls images from registry
	$(foreach service_name, \
		$(STACK_SERVICES), \
		docker pull $(DOCKER_REGISTRY)/$(service_name):$(DOCKER_IMAGE_TAG) \
	)

# Setup & run service/containers ------

.PHONY: .init
.init: ## ensures swarm cluster is initialized
	$(if $(SWARM_HOSTS), , docker swarm init)


.PHONY:
test-network: .init ## ensures test-network if `{SIMCORE_NETWORK}` is not in place
	$(if $(filter $(SIMCORE_NETWORK), $(shell docker network ls --format="{{.Name}}")) \
		, docker network ls --filter="name==$(SIMCORE_NETWORK)" \
		, docker network create --attachable --driver=overlay $(SIMCORE_NETWORK) \
	)

.PHONY: run
run: ## starts jupyter notebook for testing (use make test-network if simcore stack is not present)
	docker-compose run --publish=8888:8888 jupyter-diagnostics

.PHONY: up
up: .init ## Deploys or updates current stack "$(STACK_NAME)"
	docker stack deploy --compose-file docker-compose.yml $(STACK_NAME)

.PHONY: down reset
down: ## Stops stack
	docker stack rm $(STACK_NAME)

reset: ## leaves swarm stopping all stacks in it
	-docker swarm leave -f


# Tests ------
# TODO: do some meaningful checks here that tests the running stack
#test-up:
#	$(error docker)

.PHONY: clean
clean: ## cleans tmp files
	@git clean -Xdf
