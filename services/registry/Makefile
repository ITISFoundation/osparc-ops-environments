.DEFAULT_GOAL := help

# Internal VARIABLES ------------------------------------------------
# STACK_NAME defaults to name of the current directory. Should not to be changed if you follow GitOps operating procedures.
STACK_NAME = $(notdir $(shell pwd))
TEMP_COMPOSE=.stack.${STACK_NAME}.yaml
REPO_BASE_DIR := $(shell git rev-parse --show-toplevel)

# TARGETS --------------------------------------------------
include ${REPO_BASE_DIR}/scripts/common.Makefile

define create-s3-bucket
	# ensure bucket is available in S3...
	@set -o allexport; \
	source .env; \
	echo Creating bucket "$${S3_BUCKET}";\
	${REPO_BASE_DIR}/scripts/create-s3-bucket.bash "$${S3_BUCKET}" && \
	set +o allexport; \
	# bucket is available in S3
endef

.PHONY: up-local
up-local: .init ${TEMP_COMPOSE}-local prune-docker-stack-configs ## Deploys registry stack
	@$(create-s3-bucket)
	docker stack deploy --with-registry-auth --prune --compose-file ${TEMP_COMPOSE}-local ${STACK_NAME}

.PHONY: up-letsencrypt-http
up-letsencrypt-http: .init ${TEMP_COMPOSE}-letsencrypt-http prune-docker-stack-configs ## Deploys registry stack using let's encrypt http challenge
	docker stack deploy --with-registry-auth --prune --compose-file ${TEMP_COMPOSE}-letsencrypt-http ${STACK_NAME}

.PHONY: up-letsencrypt-dns
up-letsencrypt-dns: .init ${TEMP_COMPOSE}-letsencrypt-dns prune-docker-stack-configs ## Deploys registry stack using let's encrypt dns challenge
	docker stack deploy --with-registry-auth --prune --compose-file ${TEMP_COMPOSE}-letsencrypt-dns ${STACK_NAME}

.PHONY: up-dalco
up-dalco: .init ${TEMP_COMPOSE} prune-docker-stack-configs ## Deploys registry stack for Dalco Cluster
	docker stack deploy --with-registry-auth --prune --compose-file ${TEMP_COMPOSE} ${STACK_NAME}

.PHONY: up-aws
up-aws: .init ${TEMP_COMPOSE}-aws prune-docker-stack-configs  ## Deploys registry on AWS
	@docker stack deploy --with-registry-auth --prune --compose-file ${TEMP_COMPOSE}-aws ${STACK_NAME}

.PHONY: up-master ## Deploys registry on master cluster
up-master: up-dalco

.PHONY: up-public ## Deploys registry on public cluster
up-public: up-dalco


# Helpers -------------------------------------------------

docker-compose.yml:  docker-compose.yml.j2 .venv .env
	@$(call jinja, $<, .env, $@)

.PHONY: ${TEMP_COMPOSE}-local
${TEMP_COMPOSE}-local: docker-compose.yml docker-compose.self-signed.yml .env
	${REPO_BASE_DIR}/scripts/docker-stack-config.bash -e .env $< docker-compose.self-signed.yml > $@

.PHONY: ${TEMP_COMPOSE}-letsencrypt-http
${TEMP_COMPOSE}-letsencrypt-http: docker-compose.yml docker-compose.letsencrypt.http.yml .env
	${REPO_BASE_DIR}/scripts/docker-stack-config.bash -e .env $< docker-compose.letsencrypt.http.yml > $@

.PHONY: ${TEMP_COMPOSE}-letsencrypt-dns
${TEMP_COMPOSE}-letsencrypt-dns: docker-compose.yml docker-compose.letsencrypt.dns.yml .env
	${REPO_BASE_DIR}/scripts/docker-stack-config.bash -e .env $< docker-compose.letsencrypt.dns.yml > $@

.PHONY: ${TEMP_COMPOSE}
${TEMP_COMPOSE}: docker-compose.yml .env
	${REPO_BASE_DIR}/scripts/docker-stack-config.bash -e .env $< > $@

.PHONY: ${TEMP_COMPOSE}-aws
${TEMP_COMPOSE}-aws: docker-compose.yml docker-compose.aws.yml .env
	${REPO_BASE_DIR}/scripts/docker-stack-config.bash -e .env $< docker-compose.aws.yml > $@
