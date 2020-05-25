.DEFAULT_GOAL := help




# Internal VARIABLES ------------------------------------------------
# STACK_NAME defaults to name of the current directory. Should not to be changed if you follow GitOps operating procedures.
STACK_NAME = $(notdir $(shell pwd))
SWARM_HOSTS = $(shell docker node ls --format={{.Hostname}} 2>/dev/null)
DOCKER_PORTAINER_ADMIN_PASSWORD_SECRET = $(shell docker secret inspect --format {{.Spec.Name}} portainer_admin_password 2>/dev/null)
TEMP_COMPOSE=.stack.${STACK_NAME}.yaml

# External VARIABLES
include .env

# TARGETS --------------------------------------------------
include $(realpath $(CURDIR)/../../scripts/common.mk)


# Makefile including function used by every services
include ../common.Makefile

.PHONY: up
up: .init .env .secrets ${TEMP_COMPOSE}  ## Deploys portainer stack
	docker stack deploy -c ${TEMP_COMPOSE} ${STACK_NAME}

.PHONY: up-letsencrypt
up-letsencrypt: .init .env .secrets ${TEMP_COMPOSE}-letsencrypt  ## Deploys portainer stack using let's encrypt
	docker stack deploy -c ${TEMP_COMPOSE}-letsencrypt ${STACK_NAME}

.PHONY: up-aws
up-aws: .init .env .secrets ${TEMP_COMPOSE}-aws  ## Deploys portainer stack in aws
	docker stack deploy -c ${TEMP_COMPOSE}-aws ${STACK_NAME}



# Helpers -------------------------------------------------

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

.PHONY: .secrets
.secrets:
	@$(if $(DOCKER_PORTAINER_ADMIN_PASSWORD_SECRET), \
		, \
		echo -n "${PORTAINER_ADMIN_PWD}" | docker secret create portainer_admin_password -  2>/dev/null; \
	)
