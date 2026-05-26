REPO_BASE_DIR := $(shell git rev-parse --show-toplevel)

include ${REPO_BASE_DIR}/scripts/common-services.Makefile
include ${REPO_BASE_DIR}/scripts/common.Makefile

#
# Targets
#

.PHONY: up
up: ${TEMP_COMPOSE} ## Deploy stack
	@docker stack deploy --with-registry-auth --prune --compose-file ${TEMP_COMPOSE} ${STACK_NAME}

#
# Artifacts
#

${TEMP_COMPOSE}: docker-compose.yml .env
	@${REPO_BASE_DIR}/scripts/docker-stack-config.bash -e .env $< > $@
