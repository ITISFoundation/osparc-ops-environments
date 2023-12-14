.DEFAULT_GOAL := help



# Internal VARIABLES ------------------------------------------------
# STACK_NAME defaults to name of the current directory. Should not to be changed if you follow GitOps operating procedures.
STACK_NAME = $(notdir $(shell pwd))
DOCKER_MINIO_ACCESS_KEY = $(shell docker secret inspect --format {{.Spec.Name}} minio_secret_key 2>/dev/null)
DOCKER_MINIO_SECRET_KEY = $(shell docker secret inspect --format {{.Spec.Name}} minio_access_key 2>/dev/null)
TEMP_COMPOSE=.stack.${STACK_NAME}.yaml
REPO_BASE_DIR := $(shell git rev-parse --show-toplevel)

# TARGETS --------------------------------------------------
include ${REPO_BASE_DIR}/scripts/common.Makefile

.PHONY: up
up: .init .env ${TEMP_COMPOSE} .create-secrets ## Deploys or updates current stack "$(STACK_NAME)" using replicas=X (defaults to 1)
	@docker stack deploy --with-registry-auth --prune --compose-file ${TEMP_COMPOSE} $(STACK_NAME)
	# "in case you created more than 1 replicas, you need to label the nodes accordingly using"
	# "'docker node update --label-add minioX=true' with X being from 1 to number of replicas."

.PHONY: up-letsencrypt-http
up-letsencrypt-http: .init .env ${TEMP_COMPOSE}-letsencrypt-http .create-secrets ## Deploys minio stack using let's encrypt http challenge
	@docker stack deploy --with-registry-auth --prune --compose-file ${TEMP_COMPOSE}-letsencrypt-http ${STACK_NAME}
	# "in case you created more than 1 replicas, you need to label the nodes accordingly using"
	# "'docker node update --label-add minioX=true' with X being from 1 to number of replicas."

.PHONY: up-letsencrypt-dns
up-letsencrypt-dns: .init .env ${TEMP_COMPOSE}-letsencrypt-dns .create-secrets ## Deploys minio stack using let's encrypt dns challenge
	@docker stack deploy --with-registry-auth --prune --compose-file ${TEMP_COMPOSE}-letsencrypt-dns ${STACK_NAME}
	# "in case you created more than 1 replicas, you need to label the nodes accordingly using"
	# "'docker node update --label-add minioX=true' with X being from 1 to number of replicas."

.PHONY: up-dalco
up-dalco: up ## Deploys minio stack for Dalco Cluster

.PHONY: up-master
up-master: up ## Deploys minio stack for Master Cluster

.PHONY: up-local
up-local: up

# Helpers -------------------------------------------------
.PHONY: .create-secrets
.venv:
	# creating virtual environment with tooling (jinja, etc)
	@python3 -m venv .venv
	@.venv/bin/pip3 install --upgrade pip wheel setuptools
	@.venv/bin/pip3 install jinja2 j2cli[yaml]

define jinja
	@.venv/bin/j2 --format=env $(1) .env -o $(2)
endef

.PHONY: ${TEMP_COMPOSE}
${TEMP_COMPOSE}: docker-compose.yaml.j2	.venv .env
	$(call jinja, $<, tmp.yaml)
	@${REPO_BASE_DIR}/scripts/docker-compose-config.bash -e .env tmp.yaml > $@
	@rm tmp.yaml

.PHONY: ${TEMP_COMPOSE}-letsencrypt-http
${TEMP_COMPOSE}-letsencrypt-http: docker-compose.yaml.j2 docker-compose.letsencrypt.http.yaml.j2 .venv .env
	$(call jinja, $<, tmp.yaml)
	$(call jinja, docker-compose.letsencrypt.http.yaml.j2, tmp-letsencrypt.http.yaml)
	@${REPO_BASE_DIR}/scripts/docker-compose-config.bash -e .env tmp.yaml tmp-letsencrypt.http.yaml > $@
	@rm tmp.yaml tmp-letsencrypt.http.yaml


.PHONY: ${TEMP_COMPOSE}-letsencrypt-dns
${TEMP_COMPOSE}-letsencrypt-dns: docker-compose.yaml.j2 docker-compose.letsencrypt.dns.yaml.j2 .venv .env
	$(call jinja, $<, tmp.yaml)
	$(call jinja, docker-compose.letsencrypt.dns.yaml.j2, tmp-letsencrypt.dns.yaml)
	@${REPO_BASE_DIR}/scripts/docker-compose-config.bash -e .env tmp.yaml tmp-letsencrypt.dns.yaml > $@
	@rm tmp.yaml tmp-letsencrypt.dns.yaml

.create-secrets:
	@$(if $(DOCKER_MINIO_ACCESS_KEY), \
		, \
		set -o allexport; source .env; set +o allexport; echo "$${MINIO_ACCESS_KEY}" | docker secret create minio_access_key -  2>/dev/null; \
	)
	@$(if $(DOCKER_MINIO_SECRET_KEY), \
		,							\
		set -o allexport; source .env; set +o allexport; echo "$${MINIO_SECRET_KEY}" | docker secret create minio_secret_key -  2>/dev/null; \
	)
