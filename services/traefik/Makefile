.DEFAULT_GOAL := help



# Internal VARIABLES ------------------------------------------------
# STACK_NAME defaults to name of the current directory. Should not to be changed if you follow GitOps operating procedures.
STACK_NAME = $(notdir $(shell pwd))
SWARM_HOSTS = $(shell docker node ls --format={{.Hostname}} 2>/dev/null)
TEMP_COMPOSE=.stack.${STACK_NAME}.yaml
# Host machine IP
MACHINE_IP = $(shell source $(realpath $(CURDIR)/../../scripts/portable.sh) && get_this_ip)

# TARGETS --------------------------------------------------
include ../../scripts/common.Makefile

.PHONY: up-local
up-local: .init .create_secrets .env ${TEMP_COMPOSE}-local ## Deploys the stack using provided certificates
	@docker stack deploy --compose-file ${TEMP_COMPOSE}-local ${STACK_NAME}

.PHONY: up-aws
up-aws: .init .env ${TEMP_COMPOSE}-aws ## Deploys the stack aws 
	@docker stack deploy --compose-file ${TEMP_COMPOSE}-aws ${STACK_NAME}

.PHONY: up-letsencrypt
up-letsencrypt: .init .env ${TEMP_COMPOSE}-letsencrypt ## Deploys the stack without certificates (self-generated or let's encrypt)
	@docker stack deploy --compose-file ${TEMP_COMPOSE}-letsencrypt ${STACK_NAME}

# Helpers -------------------------------------------------

.PHONY: ${TEMP_COMPOSE}-local .env
${TEMP_COMPOSE}-local: docker-compose.yml docker-compose.local.yml
	@set -o allexport; \
	source .env; \
	set +o allexport; \
	docker-compose -f $< -f docker-compose.local.yml --log-level=ERROR config > $@

.PHONY: ${TEMP_COMPOSE}-letsencrypt
${TEMP_COMPOSE}-letsencrypt: docker-compose.yml docker-compose.letsencrypt.yml
	@docker-compose -f $< -f docker-compose.letsencrypt.yml --log-level=ERROR config > $@

.PHONY: ${TEMP_COMPOSE}-aws
${TEMP_COMPOSE}-aws: docker-compose.yml docker-compose.aws.yml
	@docker-compose -f $< -f docker-compose.aws.yml --log-level=ERROR config > $@


.PHONY: .create_secrets
.create_secrets: secrets/domain.crt secrets/domain.key secrets/rootca.crt
	@if [[ ! $$(docker secret ls | grep -w domain.crt) ]]; then docker secret create domain.crt secrets/domain.crt; fi;
	@if [[ ! $$(docker secret ls | grep -w domain.key) ]]; then docker secret create domain.key secrets/domain.key; fi;
	@if [[ ! $$(docker secret ls | grep -w rootca.crt) ]]; then if [ ! -f secrets/rootca.crt ]; then cp secrets/domain.crt secrets/rootca.crt; fi; docker secret create rootca.crt secrets/rootca.crt; fi;

.PHONY: .env
.env: template.env ../../repo.config
	@set -o allexport; \
	source $(realpath $(CURDIR)/../../repo.config); \
	TRAEFIK_PASSWORD=\'$$(docker run --rm --entrypoint htpasswd registry:2.6 -nb "$$TRAEFIK_USER" "$$TRAEFIK_PASSWORD" | cut -d ':' -f2)\';\
	export TRAEFIK_PASSWORD;\
	set +o allexport; \
	envsubst < $< > $@
