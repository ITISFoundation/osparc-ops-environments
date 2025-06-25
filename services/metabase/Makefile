REPO_BASE_DIR := $(shell git rev-parse --show-toplevel)

include ${REPO_BASE_DIR}/scripts/common.Makefile
include ${REPO_BASE_DIR}/scripts/common-services.Makefile

.PHONY: up
up: ${TEMP_COMPOSE}  ## Deploys metabase stack

${TEMP_COMPOSE}: docker-compose.yml .env
	@${REPO_BASE_DIR}/scripts/docker-stack-config.bash -e .env $< > $@
