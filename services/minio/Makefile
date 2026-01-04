REPO_BASE_DIR := $(shell git rev-parse --show-toplevel)

include ${REPO_BASE_DIR}/scripts/common-services.Makefile
# common-services.Makefile should be included first as common.Makefile
# relies on STACK_NAME var which is defined in common-services.Makefile
include ${REPO_BASE_DIR}/scripts/common.Makefile

DOCKER_MINIO_ACCESS_KEY = $(shell docker secret inspect --format {{.Spec.Name}} minio_secret_key 2>/dev/null)
DOCKER_MINIO_SECRET_KEY = $(shell docker secret inspect --format {{.Spec.Name}} minio_access_key 2>/dev/null)

#
# Targets
#

.PHONY: .up
.up: ${TEMP_COMPOSE} .create-secrets
	@docker stack deploy --with-registry-auth --prune --compose-file ${TEMP_COMPOSE} $(STACK_NAME)

.PHONY: .up-master
.up-master: .up

.PHONY: .up-public
.up-public: .up

.PHONY: .up-dalco
.up-dalco: .up

.PHONY: .up-local
.up-local: .up

.PHONY: .up-aws
.up-aws:
	$(fail "Use native AWS S3 GUI")

#
# Artifacts
#

.PHONY: ${TEMP_COMPOSE}
${TEMP_COMPOSE}: docker-compose.yaml venv .env
	@${REPO_BASE_DIR}/scripts/docker-stack-config.bash -e .env docker-compose.yaml > $@

#
# Helpers
#

.create-secrets:
	@$(if $(DOCKER_MINIO_ACCESS_KEY), \
		, \
		set -o allexport; source .env; set +o allexport; echo "$${MINIO_ACCESS_KEY}" | docker secret create minio_access_key -  2>/dev/null; \
	)
	@$(if $(DOCKER_MINIO_SECRET_KEY), \
		,							\
		set -o allexport; source .env; set +o allexport; echo "$${MINIO_SECRET_KEY}" | docker secret create minio_secret_key -  2>/dev/null; \
	)
