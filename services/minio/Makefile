.DEFAULT_GOAL := help



# Internal VARIABLES ------------------------------------------------
# STACK_NAME defaults to name of the current directory. Should not to be changed if you follow GitOps operating procedures.
STACK_NAME = $(notdir $(shell pwd))
SWARM_HOSTS = $(shell docker node ls --format={{.Hostname}} 2>/dev/null)
DOCKER_MINIO_ACCESS_KEY = $(shell docker secret inspect --format {{.Spec.Name}} minio_secret_key 2>/dev/null)
DOCKER_MINIO_SECRET_KEY = $(shell docker secret inspect --format {{.Spec.Name}} minio_access_key 2>/dev/null)
TEMP_COMPOSE=.stack.${STACK_NAME}.yaml


# TARGETS --------------------------------------------------
include ../../scripts/common.Makefile

.PHONY: up
up: .init .env ${TEMP_COMPOSE} .create-secrets ## Deploys or updates current stack "$(STACK_NAME)" using replicas=X (defaults to 1)
	@docker stack deploy --compose-file ${TEMP_COMPOSE} $(STACK_NAME)
	# "in case you created more than 1 replicas, you need to label the nodes accordingly using"
	# "'docker node update --label-add minioX=true' with X being from 1 to number of replicas."

.PHONY: up-letsencrypt
up-letsencrypt: .init .env ${TEMP_COMPOSE}-letsencrypt .create-secrets ## Deploys minio stack using let's encrypt
	@docker stack deploy --compose-file ${TEMP_COMPOSE}-letsencrypt ${STACK_NAME}
	# "in case you created more than 1 replicas, you need to label the nodes accordingly using"
	# "'docker node update --label-add minioX=true' with X being from 1 to number of replicas."

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
${TEMP_COMPOSE}: docker-compose.yaml.j2	.venv
	$(call jinja, $<, tmp.yaml)
	@docker-compose -f tmp.yaml --log-level=ERROR config > $@
	@rm tmp.yaml

.PHONY: ${TEMP_COMPOSE}-letsencrypt
${TEMP_COMPOSE}-letsencrypt: docker-compose.yaml.j2 docker-compose.letsencrypt.yaml.j2 .venv
	$(call jinja, $<, tmp.yaml)
	$(call jinja, docker-compose.letsencrypt.yaml.j2, tmp-letsencrypt.yaml)
	@docker-compose -f tmp.yaml -f tmp-letsencrypt.yaml --log-level=ERROR config > $@
	@rm tmp.yaml tmp-letsencrypt.yaml

.create-secrets:
	@$(if $(DOCKER_MINIO_ACCESS_KEY), \
		, \
		set -o allexport; source .env; set +o allexport; echo "$${MINIO_ACCESS_KEY}" | docker secret create minio_access_key -  2>/dev/null; \
	)
	@$(if $(DOCKER_MINIO_SECRET_KEY), \
		,							\
		set -o allexport; source .env; set +o allexport; echo "$${MINIO_SECRET_KEY}" | docker secret create minio_secret_key -  2>/dev/null; \
	)
