
PREDEFINED_VARIABLES := $(.VARIABLES)

# If you see pwd_unknown showing up, this is why. Re-calibrate your system.
PWD ?= pwd_unknown

# STACK_NAME defaults to name of the current directory. Should not to be changed if you follow GitOps operating procedures.
STACK_NAME = $(notdir $(PWD))

# VARIABLES ------------------------------------------------
#
# - these variables parametrize the monitoring config
# - monitoring of osparc-simcore stack
# - defaults corresponds to osparc-simcore stack in development mode
# - all services to monitor must be in MONITORED_NETWORK
#

# Network that includes all services to monitor
#  - the idea is that it shall connect osparc stack network so that e.g. cadvisor can monitor ALL the stack
#  - by default it will create an overal attachable network called monitored_network
MONITORED_NETWORK ?= monitored_network

# postgres db ulr
POSTGRES_EXPORTER_DATA_SOURCE_NAME ?= postgresql://simcore:simcore@postgres:5432/simcoredb?sslmode=disable

# Add here more ...


export MONITORED_NETWORK
export POSTGRES_EXPORTER_DATA_SOURCE_NAME


# TARGETS --------------------------------------------------

.PHONY: help
help: ## This colourful help
	@awk 'BEGIN {FS = ":.*?## "} /^[a-zA-Z_-]+:.*?## / {printf "\033[36m%-20s\033[0m %s\n", $$1, $$2}' $(MAKEFILE_LIST)

.DEFAULT_GOAL := help


.PHONY: up
.make-init:
	$(if $(shell docker stack ls --format="{{.Name}}"),,docker swarm init)
	@touch .make-init

up: .make-init ## Inits swarm and deploys current stack
	$(if $(filter $(MONITORED_NETWORK), $(shell docker network ls --format="{{.Name}}")) \
		, @echo Network in place \
		, docker network create --attachable --driver=overlay $(MONITORED_NETWORK) \
	)
	docker stack deploy -c docker-compose.yml $(STACK_NAME)

.PHONY: down reset
down: ## Stops stack
	# stops current stack
	docker stack rm $(STACK_NAME)

reset: ## stops all stacks and leaves swarm
	# leaves swarm stopping all stacks in it
	-rm -f .make-init
	-docker swarm leave -f
	

.PHONY: info
info: ## General info
	$(info VARIABLES ------------)
	$(wildcard )
	$(foreach v,                                                                           \
		$(filter-out $(PREDEFINED_VARIABLES) PREDEFINED_VARIABLES, $(sort $(.VARIABLES))), \
		$(info $(v)=$($(v)))                                                               \
	)
	@echo ""
	docker stack ls 2>/dev/null
	@echo ""
	docker ps 2>/dev/null
	@echo ""
	docker stack ps $(STACK_NAME) 2>/dev/null
	@echo ""
	docker stack services $(STACK_NAME) 2>/dev/null	
	@echo ""
	docker network ls

