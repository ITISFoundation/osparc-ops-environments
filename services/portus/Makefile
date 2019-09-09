.DEFAULT_GOAL := help
PREDEFINED_VARIABLES := $(.VARIABLES)

# If you see pwd_unknown showing up, this is why. Re-calibrate your system.
PWD ?= pwd_unknown
# Internal VARIABLES ------------------------------------------------
# STACK_NAME defaults to name of the current directory. Should not to be changed if you follow GitOps operating procedures.
STACK_NAME = $(notdir $(PWD))
SWARM_HOSTS = $(shell docker node ls --format={{.Hostname}} 2>/dev/null)
DOCKER_SECRET_PORTUS_KEY = $(shell docker secret inspect --format {{.Spec.Name}} portus_secret_key 2>/dev/null)
DOCKER_SECRET_PORTUS_CERT = $(shell docker secret inspect --format {{.Spec.Name}} portus_secret_cert 2>/dev/null)
TEMP_COMPOSE=.stack.${STACK_NAME}.yaml

# External VARIABLES
$(if $(wildcard .env), , $(shell cp .env.config .env))
include .env

# exports
export S3_ENDPOINT ?= $(shell hostname -I | cut -d ' ' -f1)
$(info S3_ENDPOINT set to ${S3_ENDPOINT})

# TARGETS --------------------------------------------------
.PHONY: help
help: ## This colourful help
	@awk 'BEGIN {FS = ":.*?## "} /^[a-zA-Z_-]+:.*?## / {printf "\033[36m%-20s\033[0m %s\n", $$1, $$2}' $(MAKEFILE_LIST)

.PHONY: up
up: .init .env ${TEMP_COMPOSE} .create-secrets  ## Deploys graylog stack
	docker stack deploy -c ${TEMP_COMPOSE} ${STACK_NAME}

.PHONY: down
down: ## Removes the stack from the swarm
	docker stack rm ${STACK_NAME}

.PHONY: leave
leave: ## Leaves swarm stopping all services in it
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
.PHONY: .init
.init: ## initializeds swarm cluster
	$(if $(SWARM_HOSTS),  \
		,                 \
		docker swarm init \
	)

.PHONY: ${TEMP_COMPOSE}
${TEMP_COMPOSE}: docker-compose.yml
	@docker-compose -f $< config > $@
	@echo "${STACK_NAME} stack file created for $@"

.portus-registry.key:
	openssl genrsa -out $@ 4096

.portus-registry.crt: .portus-registry.key
	openssl req -x509 -new -nodes -key $< -days 10000 \
	-subj "/C=US/ST=Denial/L=ZH/O=ITIS" -out $@

.PHONY: .create-secrets
.create-secrets: .portus-registry.key .portus-registry.crt
	@$(if $(DOCKER_SECRET_PORTUS_KEY), \
		, \
		echo ""; \
		docker secret create portus_secret_key .portus-registry.key  2>/dev/null; \
	)
	@$(if $(DOCKER_SECRET_PORTUS_CERT), \
		,							\
		echo ""; \
		docker secret create portus_secret_cert .portus-registry.crt  2>/dev/null; \
	)
