.DEFAULT_GOAL := help

# Internal VARIABLES ------------------------------------------------
# STACK_NAME defaults to name of the current directory. Should not to be changed if you follow GitOps operating procedures.
STACK_NAME = $(notdir $(shell pwd))
SWARM_HOSTS = $(shell docker node ls --format={{.Hostname}} 2>/dev/null)
TEMP_COMPOSE=.stack.${STACK_NAME}.yaml

# External VARIABLES
include .env

# Makefile including function used by every services
include ../common.Makefile

# TARGETS --------------------------------------------------
include $(realpath $(CURDIR)/../../scripts/common.mk)

.PHONY: up
up: .init .env ${TEMP_COMPOSE}  ## Deploys graylog stack
	docker stack deploy -c ${TEMP_COMPOSE} ${STACK_NAME}

.PHONY: up-letsencrypt
up-letsencrypt: .init .env ${TEMP_COMPOSE}-letsencrypt  ## Deploys graylog stack using let's encrypt
	docker stack deploy -c ${TEMP_COMPOSE}-letsencrypt ${STACK_NAME}

.PHONY: up-aws
up-aws: .init .env ${TEMP_COMPOSE}-aws  ## Deploys graylog stack using let's encrypt
	docker stack deploy -c ${TEMP_COMPOSE}-aws ${STACK_NAME}

.PHONY: ${TEMP_COMPOSE}
${TEMP_COMPOSE}: docker-compose.yml
	@docker-compose -f $< config > $@
	@echo "${STACK_NAME} stack file created for in $@"

.PHONY: ${TEMP_COMPOSE}-letsencrypt
${TEMP_COMPOSE}-letsencrypt: docker-compose.yml docker-compose.letsencrypt.yml
	@docker-compose -f $< -f docker-compose.letsencrypt.yml config > $@
	@echo "${STACK_NAME} stack file created for in $@"

.PHONY: ${TEMP_COMPOSE}-aws
${TEMP_COMPOSE}-aws: docker-compose.yml docker-compose.aws.yml
	@docker-compose -f $< -f docker-compose.aws.yml config > $@
	@echo "${STACK_NAME} stack file created for in $@"
