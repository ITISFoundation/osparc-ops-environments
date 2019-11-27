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

.PHONY: up
up: .init .create_secrets .env ${TEMP_COMPOSE}  ## Deploys the stack using provided certificates
	# creating bucket
	@$(create-s3-bucket)
ifneq ("$(wildcard secrets/domain.crt) $(wildcard secrets/domain.key)", "")
	@docker stack deploy -c ${TEMP_COMPOSE} ${STACK_NAME}
else
	$(error please copy your certificate to secrets/domain.crt and private key to secrets/domain.key)
endif

.PHONY: up-letsencrypt
up-letsencrypt: .init .env ${TEMP_COMPOSE}-letsencrypt  ## Deploys portainer stack using let's encrypt
	# creating bucket
	@$(create-s3-bucket)
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



# Self-signed authority ----------------------------------
secrets/rootca.key:
	@openssl genrsa -out $@ 2048

secrets/rootca.crt: secrets/rootca.key
	@openssl req -x509 -new -nodes -key $< \
		-subj "/C=US/ST=sparc/O=oSparc/CN=IT'IS oSparc" \
		-sha256 -days 10000 -out $@;

install-root-certificate: secrets/rootca.crt ## installs a certificate in the host system
	# installing certificate in trusted root certificates and restarting docker daemon...
	@$(if $(IS_WSL),                                            \
		certutil.exe -user -addstore -f root $<;				\
		sudo cp $< /usr/local/share/ca-certificates/osparc.crt; \
		sudo update-ca-certificates;                            \
		echo "Please restart the DOCKER service now..." && read -n 1; \
		echo "Is the DOCKER service ready? press when ready" && read -n 1; \
	,                                                           \
		sudo cp $< /usr/local/share/ca-certificates/osparc.crt; \
		sudo update-ca-certificates;                            \
		echo "# restarting docker daemon";                      \
		sudo systemctl restart docker                           \
	)

remove-root-certificate: ## removes the certificate from the host system
	# deleting certificate from trusted root certificates...
	-@$(if $(IS_WSL), \
		certutil.exe -user -delstore -f root "*sparc*"\
		sudo rm -f /usr/local/share/ca-certificates/osparc.crt; \
		sudo update-ca-certificates \
	,\
		sudo rm -f /usr/local/share/ca-certificates/osparc.crt; \
		sudo update-ca-certificates \
	)

# self-signed portus certicates --------------------------------------------
extfile.cnf:
	@echo "subjectAltName = DNS:${MACHINE_FQDN}" > $@ #You can use IP:your_IP or DNS:host_name

secrets/domain.key:
	@openssl genrsa -out $@ 2048

secrets/portus.csr: secrets/domain.key
	@openssl req -new -key $< -out $@ \
 		-subj "/C=US/ST=sparc/O=oSparc/CN=${MACHINE_FQDN}"

secrets/domain.crt: secrets/portus.csr secrets/rootca.crt secrets/rootca.key extfile.cnf
	@openssl x509 -req -in secrets/portus.csr -CA secrets/rootca.crt -extfile \
		extfile.cnf -CAkey secrets/rootca.key -CAcreateserial \
		-out secrets/domain.crt -days 500 -sha256

.PHONY: create-certificates
create-certificates: secrets/domain.crt secrets/domain.key secrets/rootca.crt

# host
.PHONY: .install-fqdn
.install-fqdn: ## installs the Full Qualified Domain Name (FQDN) as a host file in the host system
	@$(if $(IS_WSL), \
	if ! grep -Fq "$(MACHINE_IP) $(MACHINE_FQDN)" /c/Windows/System32/drivers/etc/hosts; then \
	echo -n "Do you wish to install the following host? [y/N] " && read ans && [ $${ans:-N} = y ]; \
	echo "please run the following in a PWshell with Admin rights:"; \
	echo "Add-Content c:\Windows\System32\drivers\etc\hosts '$(MACHINE_IP) $(MACHINE_FQDN)'"; \
	echo "OR please run the following in a CMD with Admin rights (note that wildcards are not accepted):"; \
	echo "echo '$(MACHINE_IP) $(MACHINE_FQDN)' >> c:\Windows\System32\drivers\etc\hosts"; \
	fi \
	, \
	if ! grep -Fq "$(MACHINE_IP) $(MACHINE_FQDN)" /etc/hosts; then \
		echo -n "Do you wish to install the following host? [y/N] " && read ans && [ $${ans:-N} = y ]; \
		sudo echo "$(MACHINE_IP) $(MACHINE_FQDN)" >> /etc/hosts;\
		echo "# restarting docker daemon";                      \
		sudo systemctl restart docker;                           \
	fi \
	)

.PHONY: .create_secrets
.create_secrets:
	@if ! docker secret ls | grep -w domain.crt >/dev/null; then docker secret create domain.crt secrets/domain.crt; fi;
	@if ! docker secret ls | grep -w domain.key >/dev/null; then docker secret create domain.key secrets/domain.key; fi;
	@if [ ! -f secrets/rootca.crt ]; then cp secrets/domain.crt secrets/rootca.crt; fi;
	@if ! docker secret ls | grep -w rootca.crt >/dev/null; then docker secret create rootca.crt secrets/rootca.crt; fi;
