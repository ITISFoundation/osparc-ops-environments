#
# Makefile TEMPLATE for a service/stack
#
#
.DEFAULT_GOAL := help

# ops common helpers
include $(realpath $(CURDIR)/../../scripts/common.mk)

# stack environs
include .env

# STACK_NAME defaults to name of the current directory. Should not to be changed if you follow GitOps operating procedures.
STACK_NAME    = $(notdir $(CURDIR))
SWARM_HOSTS   = $(shell docker node ls --format={{.Hostname}} 2>/dev/null)
STACK_CONFIG  = .stack-$(STACK_NAME).yml

# CLI ARGUMENTS --------------------------------------------------
# Network from which services are reverse-proxied
#  - by default it will create an overal attachable network called public_network
ifeq ($(public_network),)
export PUBLIC_NETWORK = public-network
else
export PUBLIC_NETWORK := $(public_network)
endif

# TARGETS --------------------------------------------------
$(STACK_CONFIG): docker-compose.yml .env
	# Creating config for stack
	docker-compose -f $< config > $@

.PHONY: up
up: $(STACK_CONFIG) .env .init-swarm  ## Deploys graylog stack
	# Deploying current stack '$(STACK_NAME)'
	docker stack deploy -c $< $(STACK_NAME)

.PHONY: down
down: ## Removes the stack from the swarm
	# Removing current stack '$(STACK_NAME)'
	docker stack rm $(STACK_NAME)

.PHONY: leave
leave: ## Leaves swarm stopping all services in it
	# Forcing swarm exit
	-@docker swarm leave -f

.PHONY: clean
clean:  ## Cleans outputs
	$(call clean-unversioned)

.PHONY: autodoc
autodoc: $(STACK_CONFIG) ## creates stack graph
	$(call docker-compose-viz,$(STACK_CONFIG_FILE))

.PHONY: .init-swarm
.init-swarm: ## Initialize swarm cluster
	# Ensures swarm is initialized
	$(if $(SWARM_HOSTS),,docker swarm init)
	# Ensures networks created
	$(if $(filter $(PUBLIC_NETWORK), $(shell docker network ls --format="{{.Name}}")) \
		, docker network ls --filter="name==$(PUBLIC_NETWORK)" \
		, docker network create --attachable --driver=overlay $(PUBLIC_NETWORK) \
	)
