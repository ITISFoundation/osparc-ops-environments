.DEFAULT_GOAL := help


# Internal VARIABLES ------------------------------------------------
# STACK_NAME defaults to name of the current directory. Should not to be changed if you follow GitOps operating procedures.
STACK_NAME = $(notdir $(shell pwd))
SWARM_HOSTS = $(shell docker node ls --format={{.Hostname}} 2>/dev/null)
TEMP_COMPOSE=.stack.${STACK_NAME}.yaml


# External VARIABLES
include .env

# TARGETS --------------------------------------------------
include $(realpath $(CURDIR)/../../scripts/common.Makefile)

# Makefile including function used by every services
include ../common.Makefile

.PHONY: up-aws
up-aws: .env ${TEMP_COMPOSE}  ## Deploys mail stack in aws
	docker stack deploy --compose-file ${TEMP_COMPOSE} ${STACK_NAME}

# Helpers -------------------------------------------------

.PHONY: ${TEMP_COMPOSE}
${TEMP_COMPOSE}: docker-compose.yml
	@docker-compose -f $< --log-level=ERROR config > $@
