.DEFAULT_GOAL := help
PREDEFINED_VARIABLES := $(.VARIABLES)

# Operating system
ifeq ($(filter Windows_NT,$(OS)),)
IS_LINUX:= $(filter Linux,$(shell uname))
IS_OSX  := $(filter Darwin,$(shell uname))
else
IS_WSL  := $(filter Microsoft,$(shell uname))
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

# External VARIABLES
$(if $(wildcard .env), , $(shell cp .env.config .env))
include .env

# exports
export S3_ENDPOINT ?= $(shell hostname -I | cut -d ' ' -f1):30000
$(info S3_ENDPOINT set to ${S3_ENDPOINT})
MACHINE_IP = $(shell hostname -I | cut -d ' ' -f1)
$(info MACHINE_FQDN set to ${MACHINE_FQDN})

# TARGETS --------------------------------------------------
.PHONY: help
help: ## This colourful help
	@awk 'BEGIN {FS = ":.*?## "} /^[a-zA-Z_-]+:.*?## / {printf "\033[36m%-20s\033[0m %s\n", $$1, $$2}' $(MAKEFILE_LIST)

.PHONY: up
up: .init .env create-certificates ${TEMP_COMPOSE}  ## Deploys graylog stack
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

.PHONY: ${TEMP_COMPOSE}
${TEMP_COMPOSE}: docker-compose.yml
	@$(DOCKER_COMPOSE) -f $< config > $@
	@echo "${STACK_NAME} stack file created for $@"

# Self-signed authority ----------------------------------
secrets/rootca.key:
	@openssl genrsa -out $@ 2048

secrets/rootca.crt: secrets/rootca.key
	@while [ -z "$$CONTINUE" ]; do \
        read -r -p "Provide valid certificate in secrets/rootca.crt and confirm. Otherwise a self-signed certificate will be generated [y/N]: " CONTINUE; \
    done ; \
    [ $$CONTINUE = "y" ] || [ $$CONTINUE = "Y" ] || \
	(echo "Generating self-signed certificate..."; \
	openssl req -x509 -new -nodes -key $< \
		-subj "/C=US/ST=sparc/O=oSparc/CN=IT'IS oSparc" \
		-sha256 -days 10000 -out $@;)


install-root-certificate: secrets/rootca.crt
	@echo "installing certificate in trusted root certificates, please confirm..."
	$(if $(IS_WIN), \
		$(shell certutil.exe -user -addstore -f root $<),\
		$(shell sudo cp $< /usr/local/share/ca-certicates/osparc.crt; sudo update-ca-certificates;))

delete-root-certificate:
	@echo "deleting certificate from trusted root certificates, please confirm..."
	$(if $(IS_WIN), \
		$(shell certutil.exe -user -delstore -f root "*sparc*"),\
		$(shell sudo rm -f /usr/local/share/ca-certicates/osparc.crt; sudo update-ca-certificates;))

# portus certicates --------------------------------------------
extfile.cnf:
	@echo "subjectAltName = DNS:${MACHINE_FQDN}" > $@ #You can use IP:your_IP or DNS:host_name

secrets/portus.key:
	@openssl genrsa -out $@ 2048

secrets/portus.csr: secrets/portus.key
	@openssl req -new -key $< -out $@ \
 		-subj "/C=US/ST=sparc/O=oSparc/CN=${MACHINE_FQDN}"

secrets/portus.crt: secrets/portus.csr secrets/rootca.crt secrets/rootca.key extfile.cnf
	@openssl x509 -req -in secrets/portus.csr -CA secrets/rootca.crt -extfile \
		extfile.cnf -CAkey secrets/rootca.key -CAcreateserial \
		-out secrets/portus.crt -days 500 -sha256

.PHONY: create-certificates
create-certificates: secrets/portus.crt secrets/portus.key secrets/rootca.crt

# host
install-full-qualified-name:
	$(if $(IS_WIN), \
		$(shell Add-Content c:\Windows\System32\drivers\etc\hosts "$(MACHINE_IP) $(MACHINE_FQDN)"),\
		$(shell sudo echo "$(MACHINE_IP) $(MACHINE_FQDN)" >> /etc/hosts;))
