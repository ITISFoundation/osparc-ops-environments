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

.PHONY: prune-docker-stack-configs-default
prune-docker-stack-configs-default: ## Clean all unused stack configs
	@# Since the introduction of rolling docker config updates old
	@# [docker config] versions are kept. This target removes them
	@# https://github.com/docker/cli/issues/203
	@#
	@# This should be run before stack update in order to
	@# keep previous config version for potential rollback
	@#
	@# This will not clean "external" configs. To achieve this extend
	@# this target in related Makefiles.
	@#
	@# Long live Kubernetes ConfigMaps!

	@for id in $$(docker config ls --filter "label=com.docker.stack.namespace=${STACK_NAME}" --format '{{.ID}}'); do \
	    docker config rm "$$id" >/dev/null 2>&1 || true; \
	done

.PHONY: prune-docker-stack-secrets-default
prune-docker-stack-secrets-default: ## Clean all unused stack secrets
	@# Same as for configs

	@for id in $$(docker secret ls --filter "label=com.docker.stack.namespace=${STACK_NAME}" --format '{{.ID}}'); do \
	    docker secret rm "$$id" >/dev/null 2>&1 || true; \
	done
