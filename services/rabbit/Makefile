REPO_BASE_DIR := $(shell git rev-parse --show-toplevel)

include ${REPO_BASE_DIR}/scripts/common-services.Makefile
# common-services.Makefile should be included first as common.Makefile
# relies on STACK_NAME var which is defined in common-services.Makefile
include ${REPO_BASE_DIR}/scripts/common.Makefile

#
# Running cluster
#

.PHONY: up
up: ${TEMP_COMPOSE} prune-docker-stack-configs prune-docker-stack-secrets ## Deploy rabbit
	@docker stack deploy --with-registry-auth --prune --compose-file ${TEMP_COMPOSE} ${STACK_NAME}

up-aws: up

up-master: up

up-dalco: up

up-local: up

up-public: up

${TEMP_COMPOSE}: docker-compose.yml .env
	@${REPO_BASE_DIR}/scripts/docker-stack-config.bash -e .env $< > $@

#
# Config / Secret files
#

configs/erlang.cookie.secret: configs/erlang.cookie.secret.template .env
	@set -a; source .env; set +a; \
	envsubst < $< > $@

configs/rabbitmq.conf: configs/rabbitmq.conf.j2 .env venv
	# generate $@
	@$(call jinja, $<, .env, $@)

configs/haproxy.cfg: configs/haproxy.cfg.j2 .env venv
	# generate $@
	@$(call jinja, $<, .env, $@)

docker-compose.yml: docker-compose.yml.j2 \
					.env \
					configs/rabbitmq.conf \
					configs/erlang.cookie.secret \
					configs/haproxy.cfg \
					venv \
					$(VENV_BIN)/j2
	@$(call jinja, $<, .env, $@)

#
# Deleting volumes (data)
#

CLEAN_VOLUMES_TEMP_COMPOSE := .stack.${STACK_NAME}.clean-volumes.yaml
CLEAN_VOLUMES_STACK_NAME := ${STACK_NAME}-clean-volumes

docker-compose.clean-volumes.yaml: docker-compose.clean-volumes.yaml.j2 .env
	@$(call jinja, $<, .env, $@)

${CLEAN_VOLUMES_TEMP_COMPOSE}: docker-compose.clean-volumes.yaml .env
	@${REPO_BASE_DIR}/scripts/docker-stack-config.bash -e .env $< > $@

TIMEOUT = 2m
delete-volumes: ${CLEAN_VOLUMES_TEMP_COMPOSE} guard-optional-TIMEOUT guard-optional-bool-FORCE_CONFIRM
delete-volumes:  ## Delete rabbit data volumes
	@$(call confirm_action,Forever delete all rabbit data?,yes,${FORCE_CONFIRM})
	## avoid accumulating tasks https://github.com/moby/moby/issues/45443
	@docker stack rm --detach=false ${CLEAN_VOLUMES_STACK_NAME}
	## use --detach=false to wait until all jobs complete successfully
	@timeout ${TIMEOUT}	\
	docker stack deploy --detach=false --with-registry-auth --prune --compose-file ${CLEAN_VOLUMES_TEMP_COMPOSE} ${CLEAN_VOLUMES_STACK_NAME}
	@docker stack rm ${CLEAN_VOLUMES_STACK_NAME}

#
# Destroy cluster with data (to start fresh new)
#

down: guard-optional-bool-FORCE_CONFIRM  ## Stop rabbit cluster
	@$(call confirm_action,Are you sure you want to stop the Rabbit cluster?,yes,${FORCE_CONFIRM})
	@docker stack rm ${STACK_NAME}

destroy-cluster-with-data: down delete-volumes  ## Destroy rabbit cluster with data
	@echo "Cluster has been destroyed. Data has been deleted"
