# HELPER Makefile that countains all the recipe that will be used by every services. Please include it in your Makefile if you add a new service

# Network from which services are reverse-proxied
#  - by default it will create an overal attachable network called public_network
ifeq ($(public_network),)
PUBLIC_NETWORK = public-network
else
PUBLIC_NETWORK := $(public_network)
endif
export PUBLIC_NETWORK

# Network that includes all services to monitor
#  - the idea is that it shall connect osparc stack network so that e.g. cadvisor can monitor ALL the stack
#  - by default it will create an overal attachable network called monitored_network
ifeq ($(monitored_network),)
MONITORED_NETWORK = monitored_network
else
MONITORED_NETWORK := $(monitored_network)
endif
export MONITORED_NETWORK


.PHONY: down
down: ## Removes the stack from the swarm
	@echo "${STACK_NAME}"
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

.PHONY: env-subst
env-subst: 
	set -o allexport; \
	source $(realpath $(CURDIR)/../../repo.config); \
	set +o allexport; \
	envsubst < "template.env" > ".env"

# Helpers -------------------------------------------------
.PHONY: .init
.init: ## initializeds swarm cluster
	@echo "Initialization launched"
	$(if $(SWARM_HOSTS),  \
		,                 \
		docker swarm init \
	)
	@$(if $(filter $(PUBLIC_NETWORK), $(shell docker network ls --format="{{.Name}}")) \
		, docker network ls --filter="name==$(PUBLIC_NETWORK)" \
		, docker network create --attachable --driver=overlay --subnet=10.10.0.0/16 $(PUBLIC_NETWORK) \
	)
	@$(if $(filter $(MONITORED_NETWORK), $(shell docker network ls --format="{{.Name}}")) \
		, docker network ls --filter="name==$(MONITORED_NETWORK)" \
		, docker network create --attachable --driver=overlay --subnet=10.11.0.0/16 $(MONITORED_NETWORK) \
	)