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
.make-init:
	docker swarm init
	@touch .make-init

up: .make-init ## Inits swarm and deploys currents stack
	HOSTNAME=$(hostname) docker stack deploy -c docker-compose.yml $(STACK_NAME)

.PHONY: down down-all
down: ## Stops stack
	docker stack rm $(STACK_NAME)

down-all: ## stops all stacks and leaves swarm
	-rm .make-init; docker swarm leave -f
	


.PHONY: info
info: ## General info
	$(info VARIABLES ------------)
	$(foreach v,                                                                             \
		$(filter-out $(PREDEFINED_VARIABLES) PREDEFINED_VARIABLES, $(sort $(.VARIABLES))), \
		$(info $(v) = $($(v)))                                                               \
	)
	@echo "\nSTACKS ---------------"
	@docker stack ls 2>/dev/null
	@echo "\nCONTAINERS -------------"
	@docker ps 2>/dev/null
	@echo "\nTASKS in $(STACK_NAME) stack -------------"
	@docker stack ps $(STACK_NAME) 2>/dev/null
	@echo "\nSERVICES  in $(STACK_NAME) stack -------------"
	@docker stack services $(STACK_NAME) 2>/dev/null
	
