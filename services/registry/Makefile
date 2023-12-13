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
up-local: .init .env ${TEMP_COMPOSE}-local  ## Deploys registry stack
	@$(create-s3-bucket)
	docker stack deploy --with-registry-auth --prune --compose-file ${TEMP_COMPOSE} ${STACK_NAME}

.PHONY: up-letsencrypt-http  ## Deploys registry stack using let's encrypt http challenge
up-letsencrypt-http: .init .env ${TEMP_COMPOSE}-letsencrypt-http
	docker stack deploy --with-registry-auth --prune --compose-file ${TEMP_COMPOSE}-letsencrypt-http ${STACK_NAME}

.PHONY: up-letsencrypt-dns ## Deploys registry stack using let's encrypt dns challenge
up-letsencrypt-dns: .init .env ${TEMP_COMPOSE}-letsencrypt-dns
	docker stack deploy --with-registry-auth --prune --compose-file ${TEMP_COMPOSE}-letsencrypt-dns ${STACK_NAME}

.PHONY: up-dalco ## Deploys registry stack for Dalco Cluster
up-dalco: .init .env ${TEMP_COMPOSE}
	docker stack deploy --with-registry-auth --prune --compose-file ${TEMP_COMPOSE} ${STACK_NAME}

.PHONY: up-aws
up-aws: .init .env ${TEMP_COMPOSE}-aws  ## Deploys registry on AWS
	@docker stack deploy --with-registry-auth --prune --compose-file ${TEMP_COMPOSE}-aws ${STACK_NAME}

.PHONY: up-master ## Deploys registry on master cluster
up-master: up-dalco

.PHONY: up-public ## Deploys registry on public cluster
up-public: up-dalco

.PHONY: up-local ## Deploys registry on local deployment
up-local: up

# Helpers -------------------------------------------------

.PHONY: ${TEMP_COMPOSE}-local
${TEMP_COMPOSE}-local: docker-compose.yml docker-compose.self-signed.yml .env
	${REPO_BASE_DIR}/scripts/docker-compose-config.bash -e .env $< docker-compose.self-signed.yml > $@

.PHONY: ${TEMP_COMPOSE}-letsencrypt-http
${TEMP_COMPOSE}-letsencrypt-http: docker-compose.yml docker-compose.letsencrypt.http.yml .env
	${REPO_BASE_DIR}/scripts/docker-compose-config.bash -e .env $< docker-compose.letsencrypt.http.yml > $@

.PHONY: ${TEMP_COMPOSE}-letsencrypt-dns
${TEMP_COMPOSE}-letsencrypt-dns: docker-compose.yml docker-compose.letsencrypt.dns.yml .env
	${REPO_BASE_DIR}/scripts/docker-compose-config.bash -e .env $< docker-compose.letsencrypt.dns.yml > $@

.PHONY: ${TEMP_COMPOSE}
${TEMP_COMPOSE}: docker-compose.yml .env
	${REPO_BASE_DIR}/scripts/docker-compose-config.bash -e .env $< > $@

.PHONY: ${TEMP_COMPOSE}-aws
${TEMP_COMPOSE}-aws: docker-compose.yml docker-compose.aws.yml docker-compose.letsencrypt.dns.yml .env
	${REPO_BASE_DIR}/scripts/docker-compose-config.bash -e .env $< docker-compose.aws.yml docker-compose.letsencrypt.dns.yml > $@
