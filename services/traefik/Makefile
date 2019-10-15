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
# Machine host IP
$(if $(IS_OSX), \
	$(MACHINE_IP = $(shell ipconfig getifaddr en0)), \
	$(MACHINE_IP = $(shell hostname -I | cut -d' ' -f1)) \
)
# Network that includes all services to monitor
#  - the idea is that it shall connect osparc stack network so that e.g. cadvisor can monitor ALL the stack
#  - by default it will create an overal attachable network called monitored_network
ifeq ($(monitored_network),)
MONITORED_NETWORK = monitored_network
else
MONITORED_NETWORK := $(monitored_network)
endif
export MONITORED_NETWORK

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
up: .init .create_secrets .env ${TEMP_COMPOSE} ## Deploys the stack using provided certificates
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
	@$(if $(filter $(PUBLIC_NETWORK), $(shell docker network ls --format="{{.Name}}")) \
		, docker network ls --filter="name==$(PUBLIC_NETWORK)" \
		, docker network create --attachable --driver=overlay $(PUBLIC_NETWORK) \
	)
	@$(if $(filter $(MONITORED_NETWORK), $(shell docker network ls --format="{{.Name}}")) \
		, docker network ls --filter="name==$(MONITORED_NETWORK)" \
		, docker network create --attachable --driver=overlay $(MONITORED_NETWORK) \
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

.PHONY: remove-root-certificate
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

.PHONY: install-full-qualified-domain-name
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
	@if ! $(DOCKER) secret ls | grep -w domain.crt >/dev/null; then $(DOCKER) secret create domain.crt secrets/domain.crt; fi;
	@if ! $(DOCKER) secret ls | grep -w domain.key >/dev/null; then $(DOCKER) secret create domain.key secrets/domain.key; fi;
	@if [ ! -f secrets/rootca.crt ]; then cp secrets/domain.crt secrets/rootca.crt; fi;
	@if ! $(DOCKER) secret ls | grep -w rootca.crt >/dev/null; then $(DOCKER) secret create rootca.crt secrets/rootca.crt; fi;