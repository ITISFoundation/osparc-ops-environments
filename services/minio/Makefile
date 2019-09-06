.DEFAULT_GOAL := help
PREDEFINED_VARIABLES := $(.VARIABLES)

# If you see pwd_unknown showing up, this is why. Re-calibrate your system.
PWD ?= pwd_unknown
# Internal VARIABLES ------------------------------------------------
# STACK_NAME defaults to name of the current directory. Should not to be changed if you follow GitOps operating procedures.
STACK_NAME = $(notdir $(PWD))
SWARM_HOSTS = $(shell docker node ls --format={{.Hostname}} 2>/dev/null)
DOCKER_MINIO_ACCESS_KEY = $(shell docker secret inspect --format {{.Spec.Name}} minio_secret_key 2>/dev/null)
DOCKER_MINIO_SECRET_KEY = $(shell docker secret inspect --format {{.Spec.Name}} minio_access_key 2>/dev/null)
TEMP_COMPOSE=stack.${STACK_NAME}.yaml

# External VARIABLES
include .env

# TARGETS --------------------------------------------------
.PHONY: help
help: ## This colourful help
	@awk 'BEGIN {FS = ":.*?## "} /^[a-zA-Z_-]+:.*?## / {printf "\033[36m%-20s\033[0m %s\n", $$1, $$2}' $(MAKEFILE_LIST)

.PHONY: up
up: .init .create-stack-file .create-secrets ## Deploys or updates current stack "$(STACK_NAME)" using replicas=X (defaults to 1)
	@docker stack deploy -c ${TEMP_COMPOSE} $(STACK_NAME)
	@echo "in case you created more than 1 replicas, you need to label the nodes accordingly using"
	@echo "'docker node update --label-add minioX=true' with X being from 1 to number of replicas."

.PHONY: down
down: ## Stops and remove stack from swarm
	-docker stack rm $(STACK_NAME)

.PHONY: leave
leave: ## leaves swarm stopping all stacks, secrets in it
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
.PHONY: .init .create-stack-file .create-secrets
.init:
	# initialize swarm cluster and install dependencies
	$(if $(SWARM_HOSTS),  \
		,                 \
		docker swarm init \
	)
.venv:
	python3 -m venv .venv
	.venv/bin/pip3 install --upgrade pip wheel setuptools
	.venv/bin/pip3 install jinja2 j2cli[yaml]

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
		echo ""; \
		echo "${MINIO_ACCESS_KEY}" | docker secret create minio_access_key -  2>/dev/null; \
		echo "created MINIO_ACCESS_KEY is ${MINIO_ACCESS_KEY}" \
	)
	@$(if $(DOCKER_MINIO_SECRET_KEY), \
		,							\
		echo ""; \
		echo "${MINIO_SECRET_KEY}" | docker secret create minio_secret_key -  2>/dev/null; \
		echo "created MINIO_SECRET_KEY is ${MINIO_SECRET_KEY}" \
	)
