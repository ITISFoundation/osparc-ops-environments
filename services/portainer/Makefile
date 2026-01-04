REPO_BASE_DIR := $(shell git rev-parse --show-toplevel)

include ${REPO_BASE_DIR}/scripts/common-services.Makefile
# common-services.Makefile should be included first as common.Makefile
# relies on STACK_NAME var which is defined in common-services.Makefile
include ${REPO_BASE_DIR}/scripts/common.Makefile

IS_PORTAINER_SERVICE_RUNNING = $(shell docker service ls | grep portainer_portainer | wc -l | grep 1)

#
# Helpers
#

.PHONY: configure-portainer-registry
configure-portainer-registry: venv $(VENV_BIN)/python $(WAIT_FOR_IT) ## Add registry to Portainer
	@$(MAKE) --no-print-directory install REQUIREMENTS_FILE=./scripts/requirements.txt
	@set -o allexport; source $(REPO_CONFIG_LOCATION); set +o allexport; \
	$(WAIT_FOR_IT) http $$PORTAINER_URL --timeout=120s --interval=5s --expect-status-code 200 && \
	$(VENV_BIN)/python ./scripts/configure_portainer_registry.py

#
# Targets
#

.PHONY: .up-local
.up-local: secrets ${TEMP_COMPOSE} ${TEMP_COMPOSE}-local
	@docker stack deploy --with-registry-auth --prune --compose-file ${TEMP_COMPOSE}-local ${STACK_NAME}
	@$(MAKE) configure-portainer-registry

.PHONY: .up-dalco
.up-dalco: secrets ${TEMP_COMPOSE}-dalco
	@docker stack deploy --with-registry-auth --prune --compose-file ${TEMP_COMPOSE}-dalco ${STACK_NAME}
	@$(MAKE) --no-print-directory configure-portainer-registry

.PHONY: .up-aws
.up-aws: secrets ${TEMP_COMPOSE}-aws
	@docker stack deploy --with-registry-auth --prune --compose-file ${TEMP_COMPOSE}-aws ${STACK_NAME}
	@$(MAKE) --no-print-directory configure-portainer-registry

.PHONY: .up-public
.up-public: .up-dalco

.PHONY: .up-master
.up-master: secrets ${TEMP_COMPOSE}-master
	@docker stack deploy --with-registry-auth --prune --compose-file ${TEMP_COMPOSE}-master ${STACK_NAME}
	@$(MAKE) --no-print-directory configure-portainer-registry

#
# Artifacts
#

.PHONY: ${TEMP_COMPOSE}
${TEMP_COMPOSE}: docker-compose.yml .env
	@${REPO_BASE_DIR}/scripts/docker-stack-config.bash -e .env $< > $@

.PHONY: ${TEMP_COMPOSE}-dalco
${TEMP_COMPOSE}-dalco: docker-compose.yml docker-compose.dalco.yml .env
	@${REPO_BASE_DIR}/scripts/docker-stack-config.bash -e .env $< docker-compose.dalco.yml  > $@

.PHONY: ${TEMP_COMPOSE}-master
${TEMP_COMPOSE}-master: docker-compose.yml docker-compose.master.yml .env
	@${REPO_BASE_DIR}/scripts/docker-stack-config.bash -e .env $< docker-compose.master.yml  > $@

.PHONY: ${TEMP_COMPOSE}-local
${TEMP_COMPOSE}-local: docker-compose.yml docker-compose.local.yml .env
	@${REPO_BASE_DIR}/scripts/docker-stack-config.bash -e .env $< docker-compose.local.yml > $@

.PHONY: ${TEMP_COMPOSE}-aws
${TEMP_COMPOSE}-aws: docker-compose.yml docker-compose.aws.yml .env
	@${REPO_BASE_DIR}/scripts/docker-stack-config.bash -e .env $< docker-compose.aws.yml > $@

.PHONY: secrets
secrets: .env ## Construct secrets for portainer pwd, to change pwd it need to be done manually https://git.speag.com/oSparc/osparc-ops-deployment-configuration/-/wikis/Update-Portainer-Password
	@if [ -z $(IS_PORTAINER_SERVICE_RUNNING) ]; then\
		echo "Setting portainer_admin_password (can only set but not update password!)" \
		&& echo "To update password follow https://portal.portainer.io/knowledge/how-do-i-reset-my-portainer-password" \
		&& docker secret rm portainer_admin_password 2>/dev/null; \
		set -o allexport; source .env; set +o allexport; \
		echo -n "$${PORTAINER_ADMIN_PWD}" | docker secret create portainer_admin_password -  2>/dev/null; \
    fi
