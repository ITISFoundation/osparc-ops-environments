PREDEFINED_VARIABLES := $(.VARIABLES)

# If you see pwd_unknown showing up, this is why. Re-calibrate your system.
PWD ?= pwd_unknown

# STACK_NAME defaults to name of the current directory. Should not to be changed if you follow GitOps operating procedures.
STACK_NAME = $(notdir $(PWD))



.PHONY: help
help: ## This colourful help
	@awk 'BEGIN {FS = ":.*?## "} /^[a-zA-Z_-]+:.*?## / {printf "\033[36m%-20s\033[0m %s\n", $$1, $$2}' $(MAKEFILE_LIST)

.DEFAULT_GOAL := help

.PHONY: up
up: ## Inits swarm and deploys currents stack
	docker swarm init
	HOSTNAME=$(hostname) docker stack deploy -c docker-compose.yml $(STACK_NAME)

.PHONY: down
down: ## Stops and leaves swarm
	docker swarm leave -f

.PHONY: info
info: ## General info
	$(info VARIABLES ------------)
	$(foreach v,                                                                             \
		$(filter-out $(PREDEFINED_VARIABLES) PREDEFINED_VARIABLES, $(sort $(.VARIABLES))), \
		$(info $(v) = $($(v)))                                                               \
	)
	@echo "\nSTACKS ---------------"
	@docker stack ls 2>/dev/null
	@echo "\nSERVICES -------------"
	@docker service ls 2>/dev/null
