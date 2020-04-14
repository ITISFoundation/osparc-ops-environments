.DEFAULT_GOAL := help


# Operating system
ifeq ($(filter Windows_NT,$(OS)),)
IS_WSL  := $(if $(findstring Microsoft,$(shell uname -a)),WSL,)
IS_OSX  := $(filter Darwin,$(shell uname -a))
IS_LINUX:= $(if $(or $(IS_WSL),$(IS_OSX)),,$(filter Linux,$(shell uname -a)))
endif
IS_WIN  := $(strip $(if $(or $(IS_LINUX),$(IS_OSX),$(IS_WSL)),,$(OS)))

# Makefile's shell
SHELL := $(if $(IS_WIN),powershell.exe,/bin/bash)



# Internal VARIABLES ------------------------------------------------
# STACK_NAME defaults to name of the current directory. Should not to be changed if you follow GitOps operating procedures.
STACK_NAME = $(notdir $(PWD))
SWARM_HOSTS = $(shell docker node ls --format={{.Hostname}} 2>/dev/null)
TEMP_COMPOSE=.stack.${STACK_NAME}.yaml

# Network from which services are reverse-proxied
#  - by default it will create an overal attachable network called public_network
ifeq ($(public_network),)
PUBLIC_NETWORK = public-network
else
PUBLIC_NETWORK := $(public_network)
endif
export PUBLIC_NETWORK

# Network that includes all services to monitor
#  - the idea is that it shall connect osparc stack network so that e.g. cadvisor can monitor ALL the stack
#  - by default it will create an overal attachable network called monitored_network
ifeq ($(monitored_network),)
MONITORED_NETWORK = monitored_network
else
MONITORED_NETWORK := $(monitored_network)
endif
export MONITORED_NETWORK

# External VARIABLES
$(if $(wildcard .env), , $(shell cp .env.config .env))
include .env

# exports
# Host machine IP
export MACHINE_IP = $(shell source $(realpath $(CURDIR)/../../scripts/portable.sh) && get_this_ip)

# TARGETS --------------------------------------------------
include $(realpath $(CURDIR)/../../scripts/common.mk)

.PHONY: up-self-signed
up-self-signed: .init .create_secrets .env ${TEMP_COMPOSE}-self-signed  ## Deploys the stack using provided certificates
	# creating bucket
	@$(create-s3-bucket)
ifneq ("$(wildcard secrets/domain.crt) $(wildcard secrets/domain.key)", "")
	@docker stack deploy -c ${TEMP_COMPOSE}-self-signed ${STACK_NAME}
else
	$(error please copy your certificate to secrets/domain.crt and private key to secrets/domain.key)
endif

.PHONY: up-no-certs
up-no-certs: .init .create-key-cert-pair .env ${TEMP_COMPOSE}  ## Deploys portainer stack using no certificates OR a valid certificate
	# creating bucket
	@$(create-s3-bucket)
	docker stack deploy -c ${TEMP_COMPOSE} ${STACK_NAME}

.PHONY: up-letsencrypt
up-letsencrypt: .init .create-key-cert-pair .env ${TEMP_COMPOSE}-letsencrypt  ## Deploys portainer stack using let's encrypt
	# creating bucket
	# @$(create-s3-bucket)
	docker stack deploy -c ${TEMP_COMPOSE}-letsencrypt ${STACK_NAME}

.PHONY: down
down: ## Removes the stack from the swarm
	docker stack rm ${STACK_NAME}

.PHONY: leave
leave: ## Leaves swarm stopping all services in it
	-docker swarm leave -f

.PHONY: clean
clean: ## Cleans unversioned files
	@git clean -dxf


# Helpers -------------------------------------------------
.PHONY: .init
.init: ## initializeds swarm cluster
	$(if $(SWARM_HOSTS),  \
		,                 \
		docker swarm init \
	)
	@$(if $(filter $(PUBLIC_NETWORK), $(shell docker network ls --format="{{.Name}}")) \
		, docker network ls --filter="name==$(PUBLIC_NETWORK)" \
		, docker network create --attachable --driver=overlay $(PUBLIC_NETWORK) \
	)
	@$(if $(filter $(MONITORED_NETWORK), $(shell docker network ls --format="{{.Name}}")) \
		, docker network ls --filter="name==$(MONITORED_NETWORK)" \
		, docker network create --attachable --driver=overlay $(MONITORED_NETWORK) \
	)

.PHONY: ${TEMP_COMPOSE}
${TEMP_COMPOSE}: docker-compose.insecure.yml
	@docker-compose -f $< config > $@
	@echo "${STACK_NAME} stack file created for $@"

.PHONY: ${TEMP_COMPOSE}-self-signed
${TEMP_COMPOSE}-self-signed: docker-compose.insecure.yml docker-compose.self-signed.yml
	@docker-compose -f $< -f docker-compose.self-signed.yml config > $@
	@echo "${STACK_NAME} stack file created for $@"

.PHONY: ${TEMP_COMPOSE}-letsencrypt
${TEMP_COMPOSE}-letsencrypt: docker-compose.insecure.yml docker-compose.letsencrypt.yml
	@docker-compose -f $< -f docker-compose.letsencrypt.yml config > $@
	@echo "${STACK_NAME} stack file created for in $@"

define create-s3-bucket
	@docker run \
		-v /etc/ssl/certs:/etc/ssl/certs:ro \
		--network host \
		-e MC_HOST_local="https://$(S3_ACCESSKEY):$(S3_SECRETKEY)@$(S3_ENDPOINT)" \
		minio/mc mb --ignore-existing local/$(S3_REGISTRY_BUCKET) 2>/dev/null
endef

secrets/portus.key:
	# generating private key
	@openssl genrsa 4096 \
		-keyout $@

secrets/portus.crt: secrets/portus.key
	# generating pub key
	@openssl req \
		-key $< \
		-new \
		-subj "/C=US/ST=sparc/O=osparc/CN=IT'IS oSparc" \
		-x509 -days 3650 -sha256 -out $@

.PHONY: .create-key-cert-pair
.create-key-cert-pair: secrets/portus.crt

.PHONY: .create_secrets
.create_secrets: .create-key-cert-pair
	@if ! $$(docker secret ls | grep -w domain.crt >/dev/null); then docker secret create domain.crt secrets/portus.crt; fi;
	@if ! $$(docker secret ls | grep -w domain.key >/dev/null); then docker secret create domain.key secrets/portus.key; fi;	
	@if ! $$(docker secret ls | grep -w rootca.crt >/dev/null); then docker secret create rootca.crt secrets/rootca.crt; fi;

