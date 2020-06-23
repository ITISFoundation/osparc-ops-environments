
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


# postgres db ulr
POSTGRES_EXPORTER_DATA_SOURCE_NAME ?= postgresql://${POSTGRES_USER}:${POSTGRES_PASSWORD}@postgres:5432/${POSTGRES_DB}?sslmode=disable
# External VARIABLES
include .env

# redis db url
REDIS_EXPORTER_DATA_SOURCE_NAME ?= redis://redis:6379

export POSTGRES_EXPORTER_DATA_SOURCE_NAME
export REDIS_EXPORTER_DATA_SOURCE_NAME


# TARGETS --------------------------------------------------
include $(realpath $(CURDIR)/../../scripts/common.Makefile)

# Makefile including function used by every services
include ../common.Makefile

.PHONY: up
up: .init ${TEMP_COMPOSE} ## Deploys or updates current stack "$(STACK_NAME)". If MONITORED_NETWORK is not specified, it will create an attachable network
	# Deploying stack '$(STACK_NAME)'
	@docker stack deploy --compose-file ${TEMP_COMPOSE} $(STACK_NAME)

.PHONY: up-letsencrypt
up-letsencrypt: .init ${TEMP_COMPOSE}-letsencrypt .env  ## Deploys or updates current stack "$(STACK_NAME)" using let's encrypt
	docker stack deploy --compose-file ${TEMP_COMPOSE}-letsencrypt ${STACK_NAME}

.PHONY: up-aws
up-aws: .init ${TEMP_COMPOSE}-aws .env  ## Deploys or updates current stack "$(STACK_NAME)" in AWS
	docker stack deploy --compose-file ${TEMP_COMPOSE}-aws ${STACK_NAME}

.PHONY: ${TEMP_COMPOSE}
${TEMP_COMPOSE}: docker-compose.yml
	@docker-compose -f $< --log-level=ERROR config > $@
	@echo "${STACK_NAME} stack file created for in $@"

.PHONY: ${TEMP_COMPOSE}-letsencrypt
${TEMP_COMPOSE}-letsencrypt: docker-compose.yml docker-compose.letsencrypt.yml
	@docker-compose -f $< -f docker-compose.letsencrypt.yml --log-level=ERROR config > $@
	@echo "${STACK_NAME} stack file created for in $@"

.PHONY: ${TEMP_COMPOSE}-aws
${TEMP_COMPOSE}-aws: docker-compose.yml docker-compose.aws.yml
	@docker-compose -f $< -f docker-compose.aws.yml --log-level=ERROR config > $@
	@echo "${STACK_NAME} stack file created for in $@"