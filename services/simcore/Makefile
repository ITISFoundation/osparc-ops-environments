.DEFAULT_GOAL := help

# Internal VARIABLES ------------------------------------------------
# STACK_NAME defaults to name of the current directory. Should not to be changed if you follow GitOps operating procedures.
STACK_NAME = $(notdir $(shell pwd))
SWARM_HOSTS = $(shell docker node ls --format={{.Hostname}} 2>/dev/null)
TEMP_COMPOSE=docker-compose.deploy.yml

# TARGETS --------------------------------------------------
REPO_BASE_DIR := $(shell git rev-parse --show-toplevel)

# TARGETS --------------------------------------------------
include ${REPO_BASE_DIR}/scripts/common.Makefile


.PHONY: configure
configure: .env ${TEMP_COMPOSE} ## Update the configuration from the template and repo.config file

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
${TEMP_COMPOSE}-aws: docker-compose.yml docker-compose.deploy.aws.yml docker-compose.deploy.letsencrypt.dns.yml
	@cat docker-compose.yml | $(_yq) '. *+ load("docker-compose.deploy.aws.yml")' | cat | \
	$(_yq) '. *+ load("docker-compose.deploy.letsencrypt.dns.yml")' > ${TEMP_COMPOSE}

.PHONY: ${TEMP_COMPOSE}-dalco
${TEMP_COMPOSE}-dalco: docker-compose.yml docker-compose.deploy.dalco.yml docker-compose.deploy.letsencrypt.dns.yml
	@cat docker-compose.yml | $(_yq) '. *+ load("docker-compose.deploy.dalco.yml")' | cat | \
	$(_yq) '. *+ load("docker-compose.deploy.letsencrypt.dns.yml")' > ${TEMP_COMPOSE}

.PHONY: ${TEMP_COMPOSE}-public
${TEMP_COMPOSE}-public: docker-compose.yml docker-compose.deploy.public.yml docker-compose.deploy.letsencrypt.dns.yml
	@cat docker-compose.yml | $(_yq) '. *+ load("docker-compose.deploy.public.yml")' | cat | \
	$(_yq) '. *+ load("docker-compose.deploy.letsencrypt.dns.yml")' > ${TEMP_COMPOSE}

.PHONY: ${TEMP_COMPOSE}-master
${TEMP_COMPOSE}-master: docker-compose.yml docker-compose.deploy.master.yml docker-compose.deploy.letsencrypt.dns.yml
	@cat docker-compose.yml | $(_yq) '. *+ load("docker-compose.deploy.master.yml")' | cat | \
	$(_yq) '. *+ load("docker-compose.deploy.letsencrypt.dns.yml")' > ${TEMP_COMPOSE}
