
PREDEFINED_VARIABLES := $(.VARIABLES)

# If you see pwd_unknown showing up, this is why. Re-calibrate your system.
PWD ?= pwd_unknown

# STACK_NAME defaults to name of the current directory. Should not to be changed if you follow GitOps operating procedures.
STACK_NAME = $(notdir $(PWD))

# VARIABLES ------------------------------------------------
#
# - these variables parametrize  ....


# TARGETS --------------------------------------------------
SWARM_HOSTS = $(shell docker node ls --format={{.Hostname}} 2>/dev/null)


.PHONY: help
help: ## This colourful help
	@awk 'BEGIN {FS = ":.*?## "} /^[a-zA-Z_-]+:.*?## / {printf "\033[36m%-20s\033[0m %s\n", $$1, $$2}' $(MAKEFILE_LIST)

.DEFAULT_GOAL := help


.PHONY: init up
init: ## initializeds swarm cluster
	$(if $(SWARM_HOSTS),  \
		,                 \
		docker swarm init \
	)

up: init ## Deploys or updates current stack "$(STACK_NAME)"
	docker stack deploy -c docker-compose.yml $(STACK_NAME)

.PHONY: down reset
down: ## Stops stack
	docker stack rm $(STACK_NAME)

reset: ## leaves swarm stopping all stacks in it
	-docker swarm leave -f


.PHONY: info
info: ## expands all variables and relevant info on stack
	$(info VARIABLES ------------)
	$(wildcard )
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
	docker stack ps $(STACK_NAME)
	@echo ""
	docker stack services $(STACK_NAME)
	@echo ""
	docker network ls
endif


