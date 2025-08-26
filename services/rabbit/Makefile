REPO_BASE_DIR := $(shell git rev-parse --show-toplevel)

include ${REPO_BASE_DIR}/scripts/common-services.Makefile
# common-services.Makefile should be included first as common.Makefile
#relies on STACK_NAME var which is defined in common-services.Makefile
include ${REPO_BASE_DIR}/scripts/common.Makefile

.PHONY: up
up: ${TEMP_COMPOSE} prune-docker-stack-configs prune-docker-stack-secrets ## Deploys metabase stack
	@docker stack deploy --with-registry-auth --prune --compose-file ${TEMP_COMPOSE} ${STACK_NAME}

up-aws: up

up-master: up

up-dalco: up

up-local: up

up-public: up

${TEMP_COMPOSE}: docker-compose.yml .env
	@${REPO_BASE_DIR}/scripts/docker-stack-config.bash -e .env $< > $@

erlang.cookie.secret: erlang.cookie.secret.template .env
	@set -a; source .env; set +a; \
	envsubst < $< > $@

rabbitmq.conf: rabbitmq.conf.j2 .env venv
	# generate $@
	@$(call jinja, $<, .env, $@)

haproxy.cfg: haproxy.cfg.j2 .env venv
	# generate $@
	@$(call jinja, $<, .env, $@)

docker-compose.yml: docker-compose.yml.j2 .env rabbitmq.conf erlang.cookie.secret haproxy.cfg venv $(VENV_BIN)/j2
	@$(call jinja, $<, .env, $@)
