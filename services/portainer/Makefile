.DEFAULT_GOAL := help
PREDEFINED_VARIABLES := $(.VARIABLES)

# If you see pwd_unknown showing up, this is why. Re-calibrate your system.
PWD ?= pwd_unknown
# Internal VARIABLES ------------------------------------------------
# STACK_NAME defaults to name of the current directory. Should not to be changed if you follow GitOps operating procedures.
STACK_NAME = $(notdir $(PWD))
SWARM_HOSTS = $(shell docker node ls --format={{.Hostname}} 2>/dev/null)
DOCKER_PORTAINER_ADMIN_PASSWORD_SECRET = $(shell docker secret inspect --format {{.Spec.Name}} portainer_admin_password 2>/dev/null)
TEMP_COMPOSE=stack.${STACK_NAME}.yaml

# External VARIABLES
include .env

# TARGETS --------------------------------------------------
.PHONY: help
help: ## This colourful help
	@awk 'BEGIN {FS = ":.*?## "} /^[a-zA-Z_-]+:.*?## / {printf "\033[36m%-20s\033[0m %s\n", $$1, $$2}' $(MAKEFILE_LIST)

.PHONY: up
up: .init .create-secrets ${TEMP_COMPOSE}  ## Deploys graylog stack
	docker stack deploy -c ${TEMP_COMPOSE} ${STACK_NAME}

.PHONY: down
down: ## Removes the stack from the swarm
	docker stack rm ${STACK_NAME}

.PHONY: leave
leave: ## Leaves swarm stopping all services in it
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

# Helpers -------------------------------------------------
.PHONY: .init
.init: ## initializeds swarm cluster
	$(if $(SWARM_HOSTS),  \
		,                 \
		docker swarm init \
	)

.PHONY: ${TEMP_COMPOSE}
${TEMP_COMPOSE}: docker-compose.yml
	@docker-compose -f $< config > $@	
	@echo "${STACK_NAME} stack file created for in $@"

.PHONY: .create-secrets
.create-secrets:
	@$(if $(DOCKER_PORTAINER_ADMIN_PASSWORD_SECRET), \
		, \
		echo ""; \
		echo "${PORTAINER_ADMIN_PWD}" | docker secret create portainer_admin_password -  2>/dev/null; \
		echo "created PORTAINER_ADMIN_PWD is ${PORTAINER_ADMIN_PWD}" \
	)