
.DEFAULT_GOAL := help

# include first so common variables are overriden later
include $(realpath $(CURDIR)/../simcore/.env)

# STACK_NAME defaults to name of the current directory. Should not to be changed if you follow GitOps operating procedures.
STACK_NAME = $(notdir $(CURDIR))
SWARM_HOSTS = $(shell docker node ls --format={{.Hostname}} 2>/dev/null)
TEMP_COMPOSE=.stack.${STACK_NAME}.yaml

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
# External VARIABLES
include .env

# redis db url
REDIS_EXPORTER_DATA_SOURCE_NAME ?= redis://redis:6379

export MONITORED_NETWORK
export POSTGRES_EXPORTER_DATA_SOURCE_NAME
export REDIS_EXPORTER_DATA_SOURCE_NAME

# Network from which services are reverse-proxied
#  - by default it will create an overal attachable network called public_network
ifeq ($(public_network),)
PUBLIC_NETWORK = public-network
else
PUBLIC_NETWORK := $(public_network)
endif
export PUBLIC_NETWORK

# TARGETS --------------------------------------------------
include $(realpath $(CURDIR)/../../scripts/common.mk)



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

up: .init-swarm ${TEMP_COMPOSE} ## Deploys or updates current stack "$(STACK_NAME)". If MONITORED_NETWORK is not specified, it will create an attachable network
	# Deploying stack '$(STACK_NAME)'
	@docker stack deploy -c ${TEMP_COMPOSE} $(STACK_NAME)

.PHONY: up-letsencrypt
up-letsencrypt: .init-swarm ${TEMP_COMPOSE}-letsencrypt .env  ## Deploys or updates current stack "$(STACK_NAME)" using let's encrypt
	docker stack deploy -c ${TEMP_COMPOSE}-letsencrypt ${STACK_NAME}

down: ## Stops stack
	# Removing stack '$(STACK_NAME)'
	@docker stack rm $(STACK_NAME)

leave: ## leaves swarm stopping all stacks in it
	# Forcing to leave swarm
	-@docker swarm leave -f

.PHONY: ${TEMP_COMPOSE}
${TEMP_COMPOSE}: docker-compose.yml
	@docker-compose -f $< config > $@
	@echo "${STACK_NAME} stack file created for in $@"

.PHONY: ${TEMP_COMPOSE}-letsencrypt
${TEMP_COMPOSE}-letsencrypt: docker-compose.yml docker-compose.letsencrypt.yml
	@docker-compose -f $< -f docker-compose.letsencrypt.yml config > $@
	@echo "${STACK_NAME} stack file created for in $@"
