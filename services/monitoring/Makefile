
.DEFAULT_GOAL        := help
PREDEFINED_VARIABLES := $(.VARIABLES)

# include first so common variables are overriden later
include $(realpath $(CURDIR)/../simcore/.env)

# STACK_NAME defaults to name of the current directory. Should not to be changed if you follow GitOps operating procedures.
STACK_NAME = $(notdir $(CURDIR))

# VARIABLES ------------------------------------------------
#
# - these variables parametrize the monitoring config
# - monitoring of osparc-simcore stack
# - defaults corresponds to osparc-simcore stack in development mode
# - all services to monitor must be in MONITORED_NETWORK
#

# Network that includes all services to monitor
#  - by default it will create an overal attachable network called monitored_network
ifeq ($(monitored_network),)
MONITORED_NETWORK = monitored_network
else
MONITORED_NETWORK := $(monitored_network)
endif

# postgres db ulr
POSTGRES_EXPORTER_DATA_SOURCE_NAME ?= postgresql://${POSTGRES_USER}:${POSTGRES_PASSWORD}@postgres:5432/${POSTGRES_DB}?sslmode=disable


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

include $(realpath $(CURDIR)/../../scripts/info.mk)


.PHONY: help
help: ## This colourful help
	@awk 'BEGIN {FS = ":.*?## "} /^[a-zA-Z_-]+:.*?## / {printf "\033[36m%-20s\033[0m %s\n", $$1, $$2}' $(MAKEFILE_LIST)



.PHONY: .init-swarm up down leave
.init-swarm: ## inits swarm cluster
	# ensures swarm is initialized
	$(if $(SWARM_HOSTS),,docker swarm init)
	# ensures networks are created
	@$(if $(filter $(PUBLIC_NETWORK), $(shell docker network ls --format="{{.Name}}")) \
		, docker network ls --filter="name==$(PUBLIC_NETWORK)" \
		, docker network create --attachable --driver=overlay $(PUBLIC_NETWORK) \
	)
	@$(if $(filter $(MONITORED_NETWORK), $(shell docker network ls --format="{{.Name}}")) \
		, docker network ls --filter="name==$(MONITORED_NETWORK)" \
		, docker network create --attachable --driver=overlay $(MONITORED_NETWORK) \
	)

up: .init-swarm ## Deploys or updates current stack "$(STACK_NAME)". If MONITORED_NETWORK is not specified, it will create an attachable network
	# Deploying stack '$(STACK_NAME)'
	@docker stack deploy -c docker-compose.yml $(STACK_NAME)

down: ## Stops stack
	# Removing stack '$(STACK_NAME)'
	@docker stack rm $(STACK_NAME)

leave: ## leaves swarm stopping all stacks in it
	# Forcing to leave swarm
	-@docker swarm leave -f
