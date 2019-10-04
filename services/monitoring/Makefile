
PREDEFINED_VARIABLES := $(.VARIABLES)

# If you see pwd_unknown showing up, this is why. Re-calibrate your system.
PWD ?= pwd_unknown

# STACK_NAME defaults to name of the current directory. Should not to be changed if you follow GitOps operating procedures.
STACK_NAME = $(notdir $(PWD))

# VARIABLES ------------------------------------------------
#
# - these variables parametrize the monitoring config
# - monitoring of osparc-simcore stack
# - defaults corresponds to osparc-simcore stack in development mode
# - all services to monitor must be in MONITORED_NETWORK
#

# Network that includes all services to monitor
#  - the idea is that it shall connect osparc stack network so that e.g. cadvisor can monitor ALL the stack
#  - by default it will create an overal attachable network called monitored_network
ifeq ($(monitored_network),)
MONITORED_NETWORK = monitored_network
else
MONITORED_NETWORK := $(monitored_network)
endif

# postgres db ulr
POSTGRES_EXPORTER_DATA_SOURCE_NAME ?= postgresql://simcore:simcore@postgres:5432/simcoredb?sslmode=disable

# Add here more ...


export MONITORED_NETWORK
export POSTGRES_EXPORTER_DATA_SOURCE_NAME

# Network from which services are reverse-proxied
#  - by default it will create an overal attachable network called public_network
ifeq ($(public_network),)
PUBLIC_NETWORK = public-network
else
PUBLIC_NETWORK := $(public_network)
endif
export PUBLIC_NETWORK

# TARGETS --------------------------------------------------
SWARM_HOSTS = $(shell docker node ls --format={{.Hostname}} 2>/dev/null)


.PHONY: help
help: ## This colourful help
	@awk 'BEGIN {FS = ":.*?## "} /^[a-zA-Z_-]+:.*?## / {printf "\033[36m%-20s\033[0m %s\n", $$1, $$2}' $(MAKEFILE_LIST)

.DEFAULT_GOAL := help


.PHONY: init up
init: ## initializeds swarm cluster
	$(if $(SWARM_HOSTS),  \
		,                 \
		docker swarm init \
	)
	$(if $(filter $(PUBLIC_NETWORK), $(shell docker network ls --format="{{.Name}}")) \
		, docker network ls --filter="name==$(PUBLIC_NETWORK)" \
		, docker network create --attachable --driver=overlay $(PUBLIC_NETWORK) \
	)

up: init ## Deploys or updates current stack "$(STACK_NAME)". If MONITORED_NETWORK is not specified, it will create an attachable network
	$(if $(filter $(MONITORED_NETWORK), $(shell docker network ls --format="{{.Name}}")) \
		, docker network ls --filter="name==$(MONITORED_NETWORK)" \
		, docker network create --attachable --driver=overlay $(MONITORED_NETWORK) \
	)
	docker stack deploy -c docker-compose.yml $(STACK_NAME)

.PHONY: down reset
down: ## Stops stack
	docker stack rm $(STACK_NAME)

reset: ## leaves swarm stopping all stacks in it
	-docker swarm leave -f


.PHONY: info
info: ## expands all variables and relevant info on stack
	$(info VARIABLES ------------)
	$(wildcard )
	$(foreach v,                                                                           \
		$(filter-out $(PREDEFINED_VARIABLES) PREDEFINED_VARIABLES, $(sort $(.VARIABLES))), \
		$(info $(v)=$($(v)))                                                               \
	)
	@echo ""
	docker ps
ifneq ($(SWARM_HOSTS), )
	@echo ""
	docker stack ls;
	@echo ""
	-docker stack ps $(STACK_NAME);
	@echo ""
	-docker stack services $(STACK_NAME)
	@echo ""
	docker network ls
endif


