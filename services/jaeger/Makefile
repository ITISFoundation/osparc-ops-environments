REPO_BASE_DIR := $(shell git rev-parse --show-toplevel)

include ${REPO_BASE_DIR}/scripts/common-services.Makefile
include ${REPO_BASE_DIR}/scripts/common.Makefile

#
# Targets
#

.PHONY: .up
.up: ${TEMP_COMPOSE}
	@docker stack deploy --with-registry-auth --prune --compose-file ${TEMP_COMPOSE} ${STACK_NAME}

.PHONY: .up-dalco
.up-dalco: .up

.PHONY: .up-master
.up-master: .up

.PHONY: .up-public
.up-public: .up

.PHONY: .up-local
.up-local: .up

.PHONY: .up-aws
.up-aws: ${TEMP_COMPOSE}-aws
	@docker stack deploy --with-registry-auth --prune --compose-file ${TEMP_COMPOSE}-aws ${STACK_NAME}

#
# Artifacts
#

docker-compose.yml: docker-compose.yml.j2 venv .env
	@$(call jinja, $<, .env, $@)

.PHONY: ${TEMP_COMPOSE}
${TEMP_COMPOSE}: docker-compose.yml
	@${REPO_BASE_DIR}/scripts/docker-stack-config.bash $< > $@

.PHONY: ${TEMP_COMPOSE}-aws
${TEMP_COMPOSE}-aws: docker-compose.yml docker-compose.aws.yml
	@${REPO_BASE_DIR}/scripts/docker-stack-config.bash $< docker-compose.aws.yml > $@
