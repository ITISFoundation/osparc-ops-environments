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
	@set -o allexport; \
	source .env; \
	echo Creating bucket "$${S3_BUCKET}";\
	${REPO_BASE_DIR}/scripts/create-s3-bucket.bash "$${S3_BUCKET}" && \
	set +o allexport; \
	# bucket is available in S3
endef

#
# Targets
#

.PHONY: .up-local
.up-local: ${TEMP_COMPOSE}-local prune-docker-stack-configs
	@$(create-s3-bucket)
	docker stack deploy --with-registry-auth --prune --compose-file $< ${STACK_NAME}

.PHONY: .up-dalco
.up-dalco: ${TEMP_COMPOSE} prune-docker-stack-configs
	docker stack deploy --with-registry-auth --prune --compose-file $< ${STACK_NAME}

.PHONY: .up-aws
.up-aws: ${TEMP_COMPOSE}-aws prune-docker-stack-configs
	@docker stack deploy --with-registry-auth --prune --compose-file $< ${STACK_NAME}

.PHONY: .up-master
.up-master: .up-dalco

.PHONY: .up-public
.up-public: .up-dalco

#
# Artifacts
#

docker-compose.yml:  docker-compose.yml.j2 venv .env
	@$(call jinja, $<, .env, $@)

.PHONY: ${TEMP_COMPOSE}-local
${TEMP_COMPOSE}-local: docker-compose.yml docker-compose.self-signed.yml .env
	${REPO_BASE_DIR}/scripts/docker-stack-config.bash -e .env $< docker-compose.self-signed.yml > $@

.PHONY: ${TEMP_COMPOSE}
${TEMP_COMPOSE}: docker-compose.yml .env
	${REPO_BASE_DIR}/scripts/docker-stack-config.bash -e .env $< > $@

.PHONY: ${TEMP_COMPOSE}-aws
${TEMP_COMPOSE}-aws: docker-compose.yml docker-compose.aws.yml .env
	${REPO_BASE_DIR}/scripts/docker-stack-config.bash -e .env $< docker-compose.aws.yml > $@
