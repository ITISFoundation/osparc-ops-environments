
PREDEFINED_VARIABLES := $(.VARIABLES)

# If you see pwd_unknown showing up, this is why. Re-calibrate your system.
PWD ?= pwd_unknown

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
SWARM_HOSTS = $(shell docker node ls --format={{.Hostname}} 2>/dev/null)


.PHONY: help
help: ## This colourful help
	@awk 'BEGIN {FS = ":.*?## "} /^[a-zA-Z_-]+:.*?## / {printf "\033[36m%-20s\033[0m %s\n", $$1, $$2}' $(MAKEFILE_LIST)

.DEFAULT_GOAL := help


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

.PHONY: test-network
test-network: ## ensures test-network if `{SIMCORE_NETWORK}` is not in place
	$(if $(filter $(SIMCORE_NETWORK), $(shell docker network ls --format="{{.Name}}")) \
		, docker network ls --filter="name==$(SIMCORE_NETWORK)" \
		, docker network create --attachable --driver=overlay $(SIMCORE_NETWORK) \
	)

.PHONY: .init
.init: ## ensures swarm cluster is initialized
	$(if $(SWARM_HOSTS), , docker swarm init)

.PHONY: run
run: ## starts jupyter notebook for testing (use make test-network if simcore stack is not present)
	docker-compose run --publish=8888:8888 jupyter-diagnostics

.PHONY: up
up: .init ## Deploys or updates current stack "$(STACK_NAME)"
	docker stack deploy -c docker-compose.yml $(STACK_NAME)

.PHONY: down reset
down: ## Stops stack
	docker stack rm $(STACK_NAME)

reset: ## leaves swarm stopping all stacks in it
	-docker swarm leave -f



# Miscelaneous ------

.PHONY: info info-more
info: ## expands all variables 	
	$(info VARIABLES ------------)
	$(foreach v,                                                                           \
		$(filter-out $(PREDEFINED_VARIABLES) PREDEFINED_VARIABLES, $(sort $(.VARIABLES))), \
		$(info $(v)=$($(v)))                                                               \
	)
	@echo ""
	@docker-compose config
	@echo "---"

info-more: info ## and relevant info on stack
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


.PHONY: clean
clean: ## cleans tmp files
	@git clean -Xdf
