.DEFAULT_GOAL := help
REPO_BASE_DIR := $(shell git rev-parse --show-toplevel)
# Makefile including function used by every services
include ${REPO_BASE_DIR}/scripts/common.Makefile



#
include ${REPO_CONFIG_LOCATION}
# Internal VARIABLES ------------------------------------------------
# STACK_NAME defaults to name of the current directory. Should not to be changed if you follow GitOps operating procedures.
ifeq ($(PREFIX_STACK_NAME),)
STACK_NAME := $(notdir $(shell pwd))
else
STACK_NAME := $(PREFIX_STACK_NAME)-$(notdir $(shell pwd))
endif

SWARM_HOSTS = $(shell docker node ls --format={{.Hostname}} 2>/dev/null)
TEMP_COMPOSE = .stack.${STACK_NAME}.yaml
TEMP_COMPOSE-devel = .stack.${STACK_NAME}.devel.yml
TEMP_COMPOSE-aws = .stack.${STACK_NAME}.aws.yml
DEPLOYMENT_AGENT_CONFIG = deployment_config.yaml
DEPLOYMENT_AGENT_CONFIG_DEFAULT = deployment_config.template.yaml



$(info STACK_NAME set to ${STACK_NAME})


.PHONY: up
up: .init ${DEPLOYMENT_AGENT_CONFIG} ${TEMP_COMPOSE} ## Deploys or updates current stack "$(STACK_NAME)"
	@docker stack deploy --with-registry-auth --prune --compose-file ${TEMP_COMPOSE} $(STACK_NAME)

.PHONY: up-devel
up-devel: .init ${DEPLOYMENT_AGENT_CONFIG} ${TEMP_COMPOSE-devel} ## Deploys or updates current stack "$(STACK_NAME)"
	@docker stack deploy --with-registry-auth --prune --compose-file ${TEMP_COMPOSE-devel} $(STACK_NAME)

.PHONY: up-dalco
up-dalco: up ## Deploys deploymentagent stack for Dalco Cluster

.PHONY: up-aws
up-aws: .init ${DEPLOYMENT_AGENT_CONFIG} ${TEMP_COMPOSE-aws} ## Deploys or updates current stack "$(STACK_NAME)" using replicas=X (defaults to 1) on aws
	@docker stack deploy --with-registry-auth --prune --compose-file ${TEMP_COMPOSE-aws} $(STACK_NAME)

.PHONY: up-master
up-master: up-dalco ## Deploys deploymentagent stack for Master Cluster

.PHONY: up-public
up-public: up-dalco

.PHONY: up-local
up-local: up

.PHONY: down
down: ## Stops and remove stack from swarm
	-@docker stack rm $(STACK_NAME)
	-@docker stack rm ${SIMCORE_STACK_NAME}


# Helpers -------------------------------------------------
.PHONY: ${DEPLOYMENT_AGENT_CONFIG}
${DEPLOYMENT_AGENT_CONFIG}: .env
	@set -o allexport; \
	source ${REPO_CONFIG_LOCATION}; \
	DOLLAR='$$'; \
	set +o allexport; \
	envsubst < ${DEPLOYMENT_AGENT_CONFIG_DEFAULT} > $@


.PHONY: ${TEMP_COMPOSE}
${TEMP_COMPOSE}: .env $(docker-compose-configs)
	@docker-compose --file docker-compose.yml --log-level=ERROR config > $@

.PHONY: ${TEMP_COMPOSE-devel}
${TEMP_COMPOSE-devel}: .env $(docker-compose-configs)
	@cat docker-compose.yml | $(_yq) '. *+ load("docker-compose.devel.yml")' > .temp$@ && \
	docker-compose --file .temp$@ --log-level=ERROR config > $@; \
	rm .temp$@


.PHONY: ${TEMP_COMPOSE-aws}
${TEMP_COMPOSE-aws}: .env $(docker-compose-configs)
	@docker-compose --file docker-compose.yml --file docker-compose.aws.yml --log-level=ERROR config > $@
