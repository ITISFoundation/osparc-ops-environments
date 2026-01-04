REPO_BASE_DIR := $(shell git rev-parse --show-toplevel)

include ${REPO_BASE_DIR}/scripts/common-services.Makefile
# common-services.Makefile should be included first as common.Makefile
# relies on STACK_NAME var which is defined in common-services.Makefile
include ${REPO_BASE_DIR}/scripts/common.Makefile

#
# Targets
#

.PHONY: .up-dalco .up-master .up-public .up-local
.up-dalco .up-master .up-public .up-local: ${TEMP_COMPOSE} filestash_config.json
	@docker stack deploy --with-registry-auth --prune --compose-file ${TEMP_COMPOSE} ${STACK_NAME}

.PHONY: .up-aws
.up-aws: ${TEMP_COMPOSE}-aws filestash_config.json
	@docker stack deploy --with-registry-auth --prune --compose-file ${TEMP_COMPOSE}-aws ${STACK_NAME}

#
# Artifacts
#

docker-compose.yml: docker-compose.yml.j2 venv .env filestash_config.json
	@$(call jinja, $<, .env, $@)

.PHONY: ${TEMP_COMPOSE}
${TEMP_COMPOSE}: docker-compose.yml .env
	@${REPO_BASE_DIR}/scripts/docker-stack-config.bash -e .env $< > $@

.PHONY: ${TEMP_COMPOSE}-aws
${TEMP_COMPOSE}-aws: docker-compose.yml docker-compose.aws.yml .env
	@${REPO_BASE_DIR}/scripts/docker-stack-config.bash -e .env $< docker-compose.aws.yml > $@

filestash_config.json: .env
	@set -o allexport; \
	source $(REPO_CONFIG_LOCATION); \
	if [ ! -d "venv" ]; \
	then\
		python3 -m venv venv;\
	fi;\
	source venv/bin/activate;\
	pip install -r requirements.txt > /dev/null 2>&1;\
	python create_config.py;\
	deactivate;
