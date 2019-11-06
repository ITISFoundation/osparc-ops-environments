.DEFAULT_GOAL := help




# Internal VARIABLES ------------------------------------------------
# STACK_NAME defaults to name of the current directory. Should not to be changed if you follow GitOps operating procedures.
STACK_NAME = $(notdir $(PWD))
SWARM_HOSTS = $(shell docker node ls --format={{.Hostname}} 2>/dev/null)
DOCKER_MINIO_ACCESS_KEY = $(shell docker secret inspect --format {{.Spec.Name}} minio_secret_key 2>/dev/null)
DOCKER_MINIO_SECRET_KEY = $(shell docker secret inspect --format {{.Spec.Name}} minio_access_key 2>/dev/null)
TEMP_COMPOSE=.stack.${STACK_NAME}.yaml

# Network from which services are reverse-proxied
#  - by default it will create an overal attachable network called public_network
ifeq ($(public_network),)
PUBLIC_NETWORK = public-network
else
PUBLIC_NETWORK := $(public_network)
endif
export PUBLIC_NETWORK

# Network that includes all services to monitor
#  - by default it will create an overal attachable network called monitored_network
ifeq ($(monitored_network),)
MONITORED_NETWORK = monitored_network
else
MONITORED_NETWORK := $(monitored_network)
endif
export MONITORED_NETWORK

# External VARIABLES
include .env

# TARGETS --------------------------------------------------
include $(realpath $(CURDIR)/../../scripts/common.mk)

.PHONY: up
up: .venv .init .env .create-stack-file .create-secrets ## Deploys or updates current stack "$(STACK_NAME)" using replicas=X (defaults to 1)
	@docker stack deploy -c ${TEMP_COMPOSE} $(STACK_NAME)
	@echo "in case you created more than 1 replicas, you need to label the nodes accordingly using"
	@echo "'docker node update --label-add minioX=true' with X being from 1 to number of replicas."

.PHONY: config
config: .create-stack-file

.PHONY: down
down: ## Stops and remove stack from swarm
	-docker stack rm $(STACK_NAME)

.PHONY: leave
leave: ## leaves swarm stopping all stacks, secrets in it
	-docker swarm leave -f

.PHONY: clean
clean: ## Cleans unversioned files
	@git clean -dxf

# Helpers -------------------------------------------------
.PHONY: .init .create-stack-file .create-secrets
.init:
	# initialize swarm cluster and install dependencies
	@$(if $(SWARM_HOSTS),  \
		,                 \
		docker swarm init \
	)
	@$(if $(filter $(PUBLIC_NETWORK), $(shell docker network ls --format="{{.Name}}")) \
		, docker network ls --filter="name==$(PUBLIC_NETWORK)" \
		, docker network create --attachable --driver=overlay $(PUBLIC_NETWORK) \
	)
	@$(if $(filter $(MONITORED_NETWORK), $(shell docker network ls --format="{{.Name}}")) \
		, docker network ls --filter="name==$(MONITORED_NETWORK)" \
		, docker network create --attachable --driver=overlay $(MONITORED_NETWORK) \
	)
.venv:
	# creating virtual environment with tooling (jinja, etc)
	@python3 -m venv .venv
	@.venv/bin/pip3 install --upgrade pip wheel setuptools
	@.venv/bin/pip3 install jinja2 j2cli[yaml]

.PHONY: ${TEMP_COMPOSE}
${TEMP_COMPOSE}: docker-compose.yaml.j2	.venv
	@.venv/bin/j2 --format=env $< .env -o tmp.yaml
	@docker-compose -f tmp.yaml config > $@
	@rm tmp.yaml
	@echo "${STACK_NAME} stack file created for ${MINIO_NUM_MINIOS} services/replicas with ${MINIO_NUM_PARTITIONS} partitions in $@"

.create-stack-file:${TEMP_COMPOSE}

.create-secrets:
	@$(if $(DOCKER_MINIO_ACCESS_KEY), \
		, \
		echo "${MINIO_ACCESS_KEY}" | docker secret create minio_access_key -  2>/dev/null; \
	)
	@$(if $(DOCKER_MINIO_SECRET_KEY), \
		,							\
		echo "${MINIO_SECRET_KEY}" | docker secret create minio_secret_key -  2>/dev/null; \
	)
