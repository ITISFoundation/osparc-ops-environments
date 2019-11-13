.DEFAULT_GOAL := help




# Internal VARIABLES ------------------------------------------------
# STACK_NAME defaults to name of the current directory. Should not to be changed if you follow GitOps operating procedures.
STACK_NAME = $(notdir $(PWD))
SWARM_HOSTS = $(shell docker node ls --format={{.Hostname}} 2>/dev/null)
DOCKER_PORTAINER_ADMIN_PASSWORD_SECRET = $(shell docker secret inspect --format {{.Spec.Name}} portainer_admin_password 2>/dev/null)
TEMP_COMPOSE=.stack.${STACK_NAME}.yaml

# Network from which services are reverse-proxied
#  - by default it will create an overal attachable network called public_network
ifeq ($(public_network),)
PUBLIC_NETWORK = public-network
else
PUBLIC_NETWORK := $(public_network)
endif
export PUBLIC_NETWORK

# External VARIABLES
include .env

# TARGETS --------------------------------------------------
include $(realpath $(CURDIR)/../../scripts/common.mk)


.PHONY: up
up: .init .env .secrets ${TEMP_COMPOSE}  ## Deploys portainer stack
	docker stack deploy -c ${TEMP_COMPOSE} ${STACK_NAME}

.PHONY: up-letsencrypt
up-letsencrypt: .init .env ${TEMP_COMPOSE}-letsencrypt  ## Deploys portainer stack using let's encrypt
	docker stack deploy -c ${TEMP_COMPOSE}-letsencrypt ${STACK_NAME}

.PHONY: down
down: ## Removes the stack from the swarm
	docker stack rm ${STACK_NAME}

.PHONY: leave
leave: ## Leaves swarm stopping all services in it
	-docker swarm leave -f

.PHONY: clean check_clean
clean: .check_clean ## Cleans all outputs
	# cleaning unversioned files in $(CURDIR)
	@git clean -dxf

.check_clean:
	@echo -n "Are you sure? [y/N] " && read ans && [ $${ans:-N} = y ]
	@echo -n "$(shell whoami), are you REALLY sure? [y/N] " && read ans && [ $${ans:-N} = y ]

# Helpers -------------------------------------------------

.PHONY: .init
.init: ## initializeds swarm cluster
	$(if $(SWARM_HOSTS),  \
		,                 \
		docker swarm init \
	)
	@$(if $(filter $(PUBLIC_NETWORK), $(shell docker network ls --format="{{.Name}}")) \
		, docker network ls --filter="name==$(PUBLIC_NETWORK)" \
		, docker network create --attachable --driver=overlay $(PUBLIC_NETWORK) \
	)

.PHONY: ${TEMP_COMPOSE}
${TEMP_COMPOSE}: docker-compose.yml
	@docker-compose -f $< config > $@
	@echo "${STACK_NAME} stack file created for in $@"

.PHONY: ${TEMP_COMPOSE}-letsencrypt
${TEMP_COMPOSE}-letsencrypt: docker-compose.yml docker-compose.letsencrypt.yml
	@docker-compose -f $< -f docker-compose.letsencrypt.yml config > $@
	@echo "${STACK_NAME} stack file created for in $@"

.PHONY: .secrets
.secrets:
	@$(if $(DOCKER_PORTAINER_ADMIN_PASSWORD_SECRET), \
		, \
		echo -n "${PORTAINER_ADMIN_PWD}" | docker secret create portainer_admin_password -  2>/dev/null; \
	)
