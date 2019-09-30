.DEFAULT_GOAL := help
PREDEFINED_VARIABLES := $(.VARIABLES)

# Operating system
ifeq ($(filter Windows_NT,$(OS)),)
IS_WSL  := $(if $(findstring Microsoft,$(shell uname -a)),WSL,)
IS_OSX  := $(filter Darwin,$(shell uname -a))
IS_LINUX:= $(if $(or $(IS_WSL),$(IS_OSX)),,$(filter Linux,$(shell uname -a)))
endif
IS_WIN  := $(strip $(if $(or $(IS_LINUX),$(IS_OSX),$(IS_WSL)),,$(OS)))
$(info + Detected OS : $(IS_LINUX)$(IS_OSX)$(IS_WSL)$(IS_WIN))

# Makefile's shell
SHELL := $(if $(IS_WIN),powershell.exe,/bin/bash)

DOCKER_COMPOSE=$(if $(IS_WIN),docker-compose.exe,docker-compose)
DOCKER        =$(if $(IS_WIN),docker.exe,docker)

# If you see pwd_unknown showing up, this is why. Re-calibrate your system.
PWD ?= pwd_unknown
# Internal VARIABLES ------------------------------------------------
# STACK_NAME defaults to name of the current directory. Should not to be changed if you follow GitOps operating procedures.
STACK_NAME = $(notdir $(PWD))
SWARM_HOSTS = $(shell $(DOCKER) node ls --format={{.Hostname}} 2>/dev/null)
TEMP_COMPOSE=.stack.${STACK_NAME}.yaml

# Network from which services are reverse-proxied
#  - by default it will create an overal attachable network called public_network
ifeq ($(public_network),)
PUBLIC_NETWORK = public-network
else
PUBLIC_NETWORK := $(public_network)
endif
export PUBLIC_NETWORK

# External VARIABLES
include .env

# TARGETS --------------------------------------------------
.PHONY: help
help: ## This colourful help
	@awk 'BEGIN {FS = ":.*?## "} /^[a-zA-Z_-]+:.*?## / {printf "\033[36m%-20s\033[0m %s\n", $$1, $$2}' $(MAKEFILE_LIST)

.PHONY: up
up: .init .env ${TEMP_COMPOSE} ## Deploys the stack using provided certificates
	$(DOCKER) stack deploy -c ${TEMP_COMPOSE} ${STACK_NAME}

.PHONY: down
down: ## Removes the stack from the swarm
	$(DOCKER) stack rm ${STACK_NAME}

.PHONY: leave
leave: ## Leaves swarm stopping all services in it
	-$(DOCKER) swarm leave -f

.PHONY: clean
clean: ## Cleans unversioned files
	@git clean -dxf

.PHONY: info
info: ## expands all variables and relevant info on stack
	$(info VARIABLES ------------)
	$(foreach v,                                                                           \
		$(filter-out $(PREDEFINED_VARIABLES) PREDEFINED_VARIABLES, $(sort $(.VARIABLES))), \
		$(info $(v)=$($(v)))                                                               \
	)
	@echo ""
	$(DOCKER) ps
ifneq ($(SWARM_HOSTS), )
	@echo ""
	$(DOCKER) stack ls
	@echo ""
	-$(DOCKER) stack ps $(STACK_NAME)
	@echo ""
	-$(DOCKER) stack services $(STACK_NAME)
	@echo ""
	$(DOCKER) network ls
endif

# Helpers -------------------------------------------------
.PHONY: .init
.init: ## initializeds swarm cluster
	$(if $(SWARM_HOSTS),  \
		,                 \
		$(DOCKER) swarm init \
	)
	$(if $(filter $(PUBLIC_NETWORK), $(shell docker network ls --format="{{.Name}}")) \
		, docker network ls --filter="name==$(PUBLIC_NETWORK)" \
		, docker network create --attachable --driver=overlay $(PUBLIC_NETWORK) \
	)

.PHONY: ${TEMP_COMPOSE}
${TEMP_COMPOSE}: docker-compose.yml
	@$(DOCKER_COMPOSE) -f $< config > $@
	@echo "${STACK_NAME} stack file created for $@"


# Self-signed certificate authority
secrets/rootca.key:
	@openssl genrsa -out $@ 2048

secrets/rootca.crt: secrets/rootca.key
	@openssl req -x509 -new -nodes -key $< \
		-subj "/C=US/ST=sparc/O=oSparc/CN=IT'IS oSparc" \
		-sha256 -days 10000 -out $@;

extfile.cnf:
	@echo "subjectAltName = DNS:${MACHINE_FQDN}" > $@ #You can use IP:your_IP or DNS:host_name

secrets/domain.key:
	@openssl genrsa -out $@ 2048

secrets/domain.csr: secrets/domain.key
	@openssl req -new -key $< -out $@ \
 		-subj "/C=US/ST=sparc/O=oSparc/CN=${MACHINE_FQDN}"

secrets/domain.crt: secrets/domain.csr secrets/rootca.crt secrets/rootca.key extfile.cnf
	@openssl x509 -req -in secrets/domain.csr -CA secrets/rootca.crt -extfile \
		extfile.cnf -CAkey secrets/rootca.key -CAcreateserial \
		-out secrets/domain.crt -days 500 -sha256

.PHONY: create-certificates
create-certificates: secrets/domain.crt secrets/domain.key secrets/rootca.crt ## create self-signed certificates and ca authority

.PHONY: install-root-certificate
install-root-certificate: secrets/rootca.crt ## installs a certificate in the host system
	$(info installing certificate in trusted root certificates...)
	$(if $(or $(IS_WIN), $(IS_WSL)), \
		-$(shell certutil.exe -user -addstore -f root $<),\
		$(shell sudo cp $< /etc/ssl/certs/osparc.crt))
	$(info restart any browser or docker engine that should use these certificate)

.PHONY: remove-root-certificate
remove-root-certificate: ## removes the certificate from the host system
	$(info deleting certificate from trusted root certificates...)
	$(if $(or $(IS_WIN), $(IS_WSL)), \
		-$(shell certutil.exe -user -delstore -f root "*sparc*"),\
		$(shell sudo rm -f /etc/ssl/certs/osparc.crt))

.PHONY: install-full-qualified-domain-name
install-full-qualified-domain-name: ## installs the Full Qualified Domain Name (FQDN) as a host file in the host system
	$(info )
	$(info to install a FQDN in your host, ADMIN rights needed)
	$(if $(or $(IS_WIN),$(IS_WSL)), \
		$(info please run the following in a PWshell with Admin rights:)\
		$(info Add-Content c:\Windows\System32\drivers\etc\hosts "$(MACHINE_IP) $(MACHINE_FQDN)"),\
		$(info please run the following in a CMD with Admin rights (note that wildcards are not accepted under Windows):)\
		$(info echo "$(MACHINE_IP) $(MACHINE_FQDN)" >> c:\Windows\System32\drivers\etc\hosts),\
		$(shell sudo echo "$(MACHINE_IP) $(MACHINE_FQDN)" >> /etc/hosts;)\
	)
	$(info afterwards restart any browser or docker engine that should use these host file)
