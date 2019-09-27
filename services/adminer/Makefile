PREDEFINED_VARIABLES := $(.VARIABLES)


# STACK_NAME defaults to name of the current directory. Should not to be changed if you follow GitOps operating procedures.
SWARM_STACK_NAME = $(notdir $(PWD))

# VARIABLES ------------------------------------------------



# TARGETS --------------------------------------------------
.DEFAULT_GOAL := help
SWARM_HOSTS    = $(shell docker node ls --format={{.Hostname}} 2>/dev/null)


.PHONY: help
help: ## This colourful help
	@awk 'BEGIN {FS = ":.*?## "} /^[a-zA-Z_-]+:.*?## / {printf "\033[36m%-20s\033[0m %s\n", $$1, $$2}' $(MAKEFILE_LIST)


# Run stack 
.PHONY: .init up down leave

.init:
	## Ensures swarm cluster is initialized
	$(if $(SWARM_HOSTS), ,docker swarm init )

up: .init ## Deploys or updates current stack "$(STACK_NAME)"
	docker stack deploy -c docker-compose.yml $(SWARM_STACK_NAME)

down: ## Stops and removes stack
	# Removing stack '$(SWARM_STACK_NAME)'
	-$(DOCKER) stack rm $(SWARM_STACK_NAME)

leave: ## leaves swarm stopping all stacks in it
	-docker swarm leave -f


# Misc: info & clean
.PHONY: info info-vars info-swarm

info: info-vars info-swarm ## all info

info-vars: ## expands all variables in makefile
	$(info VARIABLES ------------)
	$(foreach v,                                                                           \
		$(filter-out $(PREDEFINED_VARIABLES) PREDEFINED_VARIABLES, $(sort $(.VARIABLES))), \
		$(info $(v)=$($(v)))                                                               \
	)
	#

info-swarm: ## displays info about stacks and networks
ifneq ($(SWARM_HOSTS), )
	# stacks in swarm
	@$(DOCKER) stack ls
	# containers (tasks) running in '$(SWARM_STACK_NAME)' stack
	-@$(DOCKER) stack ps $(SWARM_STACK_NAME)
	# services in '$(SWARM_STACK_NAME)' stack
	-@$(DOCKER) stack services $(SWARM_STACK_NAME)
	# networks
	@$(DOCKER) network ls
endif


.PHONY: clean .check_clean
clean: .check_clean ## Cleans all outputs
	# removing unversioned
	@git clean -dxf -e .vscode/

.check_clean:
	@echo -n "Are you sure? [y/N] " && read ans && [ $${ans:-N} = y ]
	@echo -n "$(shell whoami), are you REALLY sure? [y/N] " && read ans && [ $${ans:-N} = y ]
