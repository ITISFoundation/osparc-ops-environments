.DEFAULT_GOAL := help

# Internal VARIABLES ------------------------------------------------
# STACK_NAME defaults to name of the current directory. Should not to be changed if you follow GitOps operating procedures.
STACK_NAME = $(notdir $(shell pwd))
TEMP_COMPOSE=docker-compose.deploy.yml

# TARGETS --------------------------------------------------
REPO_BASE_DIR := $(shell git rev-parse --show-toplevel)

# TARGETS --------------------------------------------------
include ${REPO_BASE_DIR}/scripts/common.Makefile

.PHONY: compose-local
compose-local: .env ${TEMP_COMPOSE}-local ## Create docker-compose.deploy for local deployment

.PHONY: compose-letsencrypt-http
compose-letsencrypt-http: .env ${TEMP_COMPOSE}-letsencrypt-http ## Create docker-compose.deploy for letsencrypt with http challenge deployment

.PHONY: compose-letsencrypt-dns
compose-letsencrypt-dns: .env ${TEMP_COMPOSE}-letsencrypt-dns ## Create docker-compose.deploy for letsencrypt with http dns deployment

.PHONY: compose-dalco
compose-dalco: .env ${TEMP_COMPOSE}-dalco ## Create docker-compose.deploy for Dalco cluster

.PHONY: compose-public
compose-public: .env ${TEMP_COMPOSE}-public ## Create docker-compose.deploy for public cluster

.PHONY: compose-aws
compose-aws: .env ${TEMP_COMPOSE}-aws ## Create docker-compose.deploy for AWS

.PHONY: compose-master
compose-master: .env ${TEMP_COMPOSE}-master ## Create docker-compose.deploy for Master


.PHONY: ${TEMP_COMPOSE}-local
${TEMP_COMPOSE}-local: docker-compose.yml docker-compose.deploy.local.yml
	@cat docker-compose.yml | $(_yq) '. *+ load("docker-compose.deploy.local.yml")' > ${TEMP_COMPOSE}

.PHONY: ${TEMP_COMPOSE}-letsencrypt-http
${TEMP_COMPOSE}-letsencrypt-http: docker-compose.yml docker-compose.deploy.letsencrypt.http.yml
	@cat docker-compose.yml | $(_yq) '. *+ load("docker-compose.deploy.letsencrypt.http.yml")' > ${TEMP_COMPOSE}

.PHONY: ${TEMP_COMPOSE}-letsencrypt-dns
${TEMP_COMPOSE}-letsencrypt-dns: docker-compose.yml docker-compose.deploy.letsencrypt.dns.yml
	@cat docker-compose.yml | $(_yq) '. *+ load("docker-compose.deploy.letsencrypt.dns.yml")' > ${TEMP_COMPOSE}

.PHONY: ${TEMP_COMPOSE}-aws
${TEMP_COMPOSE}-aws: docker-compose.yml docker-compose.deploy.aws.yml
	@cat docker-compose.yml | $(_yq) '. *+ load("docker-compose.deploy.aws.yml")' > ${TEMP_COMPOSE}

.PHONY: ${TEMP_COMPOSE}-dalco
${TEMP_COMPOSE}-dalco: docker-compose.yml docker-compose.deploy.dalco.yml
	@cat docker-compose.yml | $(_yq) '. *+ load("docker-compose.deploy.dalco.yml")' > ${TEMP_COMPOSE}

.PHONY: ${TEMP_COMPOSE}-public
${TEMP_COMPOSE}-public: docker-compose.yml docker-compose.deploy.public.yml docker-compose.deploy.letsencrypt.dns.yml
	@cat docker-compose.yml | $(_yq) '. *+ load("docker-compose.deploy.public.yml")' > ${TEMP_COMPOSE}

.PHONY: ${TEMP_COMPOSE}-master
${TEMP_COMPOSE}-master: docker-compose.yml docker-compose.deploy.master.yml docker-compose.deploy.letsencrypt.dns.yml
	@cat docker-compose.yml | $(_yq) '. *+ load("docker-compose.deploy.master.yml")' > ${TEMP_COMPOSE}

.PHONY: .env
.env: $(REPO_CONFIG_LOCATION) # Overwriting the default from 'common.Makefile', to avoid having ato maintain a template.env file here.
	@set -o allexport; \
	cp -f $(REPO_CONFIG_LOCATION) .env; \
	echo DEPLOYMENT_API_DOMAIN_CAPTURE_TRAEFIK_RULE=\''${DEPLOYMENT_API_DOMAIN_CAPTURE_TRAEFIK_RULE}'\' >> .env; \
	echo DEPLOYMENT_FQDNS_CAPTURE_TRAEFIK_RULE_CATCHALL=\''${DEPLOYMENT_FQDNS_CAPTURE_TRAEFIK_RULE_CATCHALL}'\' >> .env; \
	echo DEPLOYMENT_FQDNS_TESTING_CAPTURE_TRAEFIK_RULE=\''${DEPLOYMENT_FQDNS_TESTING_CAPTURE_TRAEFIK_RULE}'\' >> .env; \
	echo DEPLOYMENT_API_DOMAIN_TESTING_CAPTURE_TRAEFIK_RULE=\''${DEPLOYMENT_API_DOMAIN_TESTING_CAPTURE_TRAEFIK_RULE}'\' >> .env; \
	echo DEPLOYMENT_FQDNS_CAPTURE_INVITATIONS=\''${DEPLOYMENT_FQDNS_CAPTURE_INVITATIONS}'\' >> .env; \
	echo DEPLOYMENT_FQDNS_PAYMENT_CAPTURE_TRAEFIK_RULE=\''${DEPLOYMENT_FQDNS_PAYMENT_CAPTURE_TRAEFIK_RULE}'\' >> .env; \
	echo DOLLAR=\'$$\' >> .env; \
	set +o allexport; \
