REPO_BASE_DIR := $(shell git rev-parse --show-toplevel)

include ${REPO_BASE_DIR}/scripts/common-services.Makefile
include ${REPO_BASE_DIR}/scripts/common.Makefile

#
# Helpers
#

define create-s3-bucket
	# ensure bucket is available in S3...
	set -o allexport; \
	source .env; \
	echo Creating bucket "$${S3_BUCKET_NAME_LOKI}";\
	export S3_ACCESS_KEY=$${S3_ACCESS_KEY_LOKI}; \
	export S3_SECRET_KEY=$${S3_SECRET_KEY_LOKI}; \
	export STORAGE_DOMAIN=$${STORAGE_DOMAIN}; \
	${REPO_BASE_DIR}/scripts/create-s3-bucket.bash "$${S3_BUCKET_NAME_LOKI}" && \
	set +o allexport; \
	# bucket is available in S3
endef

.PHONY: configure
configure: .env venv ## Configure graylog
	@cd scripts;\
	VIRTUAL_ENV=$(VENV_DIR) $(UV) pip install --requirement requirements.txt > /dev/null 2>&1;\
	set -o allexport; \
	source ../$<;\
	set +o allexport; \
	envsubst < alerts.template.yaml > alerts.yaml;\
	$(VENV_BIN)/python configure.py;

#
# Deploy targets
#

UP_COMMON_DEPENDENCIES = prune-docker-stack-configs

.PHONY: .up-dalco
.up-dalco: ${TEMP_COMPOSE}-dalco ${UP_COMMON_DEPENDENCIES}
	@docker stack deploy --with-registry-auth --prune --compose-file ${TEMP_COMPOSE}-dalco ${STACK_NAME}
	$(MAKE) configure

.PHONY: .up-public
.up-public: .up-dalco

.PHONY: .up-aws
.up-aws: ${TEMP_COMPOSE}-aws ${UP_COMMON_DEPENDENCIES}
	@docker stack deploy --with-registry-auth --prune --compose-file ${TEMP_COMPOSE}-aws ${STACK_NAME}
	$(MAKE) configure

.PHONY: .up-master
.up-master: ${TEMP_COMPOSE}-master ${UP_COMMON_DEPENDENCIES}
	@docker stack deploy --with-registry-auth --prune --compose-file ${TEMP_COMPOSE}-master ${STACK_NAME}
	$(MAKE) configure

.PHONY: .up-local
.up-local: ${TEMP_COMPOSE}-local ${UP_COMMON_DEPENDENCIES}
	@$(create-s3-bucket)
	@docker stack deploy --with-registry-auth --prune --compose-file ${TEMP_COMPOSE}-local ${STACK_NAME}
	$(MAKE) configure

#
# Artifacts
#

.PHONY: .env
.env: template.env $(REPO_CONFIG_LOCATION)
	@set -o allexport; \
	source $(REPO_CONFIG_LOCATION); \
	GRAYLOG_ROOT_PASSWORD_SHA2=$$(echo -n "$${GRAYLOG_ROOT_PASSWORD}" | sha256sum | cut -d ' ' -f1);\
	export GRAYLOG_ROOT_PASSWORD_SHA2;\
	GRAYLOG_PASSWORD_SECRET=$$(tr -dc A-Za-z0-9 </dev/urandom | head -c 16 ; echo '');\
	export GRAYLOG_PASSWORD_SECRET;\
	STACK_NAME=$(STACK_NAME); \
	export STACK_NAME; \
	set +o allexport; \
	envsubst < $< > $@

vector.yaml: vector.yaml.j2 .env $(VENV_BIN)/j2
	@$(call jinja, $<, .env, $@)

docker-compose.yml: docker-compose.yml.j2 vector.yaml $(VENV_BIN)/j2 .env
	@$(call jinja, $<, .env, $@)

.PHONY: ${TEMP_COMPOSE}
${TEMP_COMPOSE}: docker-compose.yml .env
	@${REPO_BASE_DIR}/scripts/docker-stack-config.bash -e .env $< > $@

.PHONY: ${TEMP_COMPOSE}-dalco
${TEMP_COMPOSE}-dalco: docker-compose.yml docker-compose.dalco.yml .env
	@${REPO_BASE_DIR}/scripts/docker-stack-config.bash -e .env $< docker-compose.dalco.yml > $@

.PHONY: ${TEMP_COMPOSE}-master
${TEMP_COMPOSE}-master: docker-compose.yml docker-compose.master.yml .env
	@${REPO_BASE_DIR}/scripts/docker-stack-config.bash -e .env $< docker-compose.master.yml > $@

.PHONY: ${TEMP_COMPOSE}-local
${TEMP_COMPOSE}-local: docker-compose.yml docker-compose.local.yml .env
	@${REPO_BASE_DIR}/scripts/docker-stack-config.bash -e .env $< docker-compose.local.yml > $@

.PHONY: ${TEMP_COMPOSE}-aws
${TEMP_COMPOSE}-aws: docker-compose.yml docker-compose.aws.yml .env
	@${REPO_BASE_DIR}/scripts/docker-stack-config.bash -e .env $< docker-compose.aws.yml > $@
