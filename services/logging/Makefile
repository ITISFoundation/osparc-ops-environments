REPO_BASE_DIR := $(shell git rev-parse --show-toplevel)

include ${REPO_BASE_DIR}/scripts/common-services.Makefile
# common-services.Makefile should be included first as common.Makefile
# relies on STACK_NAME var which is defined in common-services.Makefile
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

# https://stackoverflow.com/a/13322549/12124525
define get_host_private_ip
	ifconfig \
	| grep -Eo 'inet (addr:)?([0-9]*\.){3}[0-9]*' \
	| grep -Eo '([0-9]*\.){3}[0-9]*' \
	| grep -v '127.0.0.1' \
	| head --lines 1
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
${TEMP_COMPOSE}: docker-compose.yml
	@${REPO_BASE_DIR}/scripts/docker-stack-config.bash -e .env $< > $@

.PHONY: ${TEMP_COMPOSE}-dalco
${TEMP_COMPOSE}-dalco: docker-compose.yml docker-compose.dalco.yml
	@${REPO_BASE_DIR}/scripts/docker-stack-config.bash -e .env $< docker-compose.dalco.yml > $@

.PHONY: ${TEMP_COMPOSE}-master .env
${TEMP_COMPOSE}-master: docker-compose.yml docker-compose.master.yml
	@${REPO_BASE_DIR}/scripts/docker-stack-config.bash -e .env $< docker-compose.master.yml > $@

.PHONY: ${TEMP_COMPOSE}-local
${TEMP_COMPOSE}-local: docker-compose.yml docker-compose.local.yml
	@${REPO_BASE_DIR}/scripts/docker-stack-config.bash -e .env $< docker-compose.local.yml > $@

.PHONY: ${TEMP_COMPOSE}-aws
${TEMP_COMPOSE}-aws: docker-compose.yml docker-compose.aws.yml
	@${REPO_BASE_DIR}/scripts/docker-stack-config.bash -e .env $< docker-compose.aws.yml > $@

#
# Deploy targets
#

.PHONY: up
up: .init .env ${TEMP_COMPOSE}  ## Deploy logging stack
	@docker stack deploy --with-registry-auth --prune --compose-file ${TEMP_COMPOSE} ${STACK_NAME}
	$(MAKE) configure

.PHONY: up-dalco
up-dalco: .init .env ${TEMP_COMPOSE}-dalco ## Deploy logging stack for Dalco Cluster
	@docker stack deploy --with-registry-auth --prune --compose-file ${TEMP_COMPOSE}-dalco ${STACK_NAME}
	$(MAKE) configure

.PHONY: up-public
up-public: up-dalco ## Deploys logging stack for public access Cluster

.PHONY: up-aws
up-aws: .init .env ${TEMP_COMPOSE}-aws  ## Deploy logging stack using let's encrypt
	@docker stack deploy --with-registry-auth --prune --compose-file ${TEMP_COMPOSE}-aws ${STACK_NAME}
	$(MAKE) configure

.PHONY: up-master
up-master: .init .env ${TEMP_COMPOSE}-master ## Deploy logging stack for master Cluster
	@docker stack deploy --with-registry-auth --prune --compose-file ${TEMP_COMPOSE}-master ${STACK_NAME}
	$(MAKE) configure

.PHONY: up-local
up-local: .init .env ${TEMP_COMPOSE}-local  ## Deploy logging stack for local cluster
	@$(create-s3-bucket)
	@docker stack deploy --with-registry-auth --prune --compose-file ${TEMP_COMPOSE}-local ${STACK_NAME}
	$(MAKE) configure
