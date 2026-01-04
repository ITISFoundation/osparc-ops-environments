.DEFAULT_GOAL := help

STACK_NAME = $(notdir $(shell pwd))
TEMP_COMPOSE=.stack.${STACK_NAME}.yaml
REPO_BASE_DIR := $(shell git rev-parse --show-toplevel)

MAKEFLAGS += --no-print-directory

#
# Common targets
#

.PHONY: up-default
up-default: ## Deploy stack (usage: `make up`)
	@set -a && source $(REPO_CONFIG_LOCATION) && set +a && \
	$(MAKE) .up-$$OSPARC_DEPLOYMENT_TARGET

.PHONY: down-default
down-default: ## Remove stack (usage: `make down`)
	@echo "${STACK_NAME}"
	@docker stack rm --detach=false ${STACK_NAME}
