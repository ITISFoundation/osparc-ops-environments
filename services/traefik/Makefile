.DEFAULT_GOAL := help


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



# Internal VARIABLES ------------------------------------------------
# STACK_NAME defaults to name of the current directory. Should not to be changed if you follow GitOps operating procedures.
STACK_NAME = $(notdir $(shell pwd))
SWARM_HOSTS = $(shell docker node ls --format={{.Hostname}} 2>/dev/null)
TEMP_COMPOSE=.stack.${STACK_NAME}.yaml
# Host machine IP
export MACHINE_IP = $(shell source $(realpath $(CURDIR)/../../scripts/portable.sh) && get_this_ip)


# External VARIABLES
include .env

# TARGETS --------------------------------------------------
include $(realpath $(CURDIR)/../../scripts/common.Makefile)

# Makefile including function used by every services
include ../common.Makefile

.PHONY: up-local
up-local: .init .create_secrets .env ${TEMP_COMPOSE}-local ## Deploys the stack using provided certificates
	docker stack deploy -c ${TEMP_COMPOSE}-local ${STACK_NAME}

.PHONY: up-aws
up-aws: .env ${TEMP_COMPOSE}-aws ## Deploys the stack aws 
	@echo "deploying ${STACK_NAME} to aws"
	docker stack deploy -c ${TEMP_COMPOSE}-aws ${STACK_NAME}

.PHONY: up-letsencrypt
up-letsencrypt: .init .env ${TEMP_COMPOSE}-letsencrypt ## Deploys the stack without certificates (self-generated or let's encrypt)
	docker stack deploy -c ${TEMP_COMPOSE}-letsencrypt ${STACK_NAME}

.PHONY: up-no-certificates
up-no-certificates: .init .env ${TEMP_COMPOSE} ## Deploys the stack without certificates (self-generated or let's encrypt)
	docker stack deploy -c ${TEMP_COMPOSE} ${STACK_NAME}


# Helpers -------------------------------------------------


.PHONY: ${TEMP_COMPOSE}-local
${TEMP_COMPOSE}-local: docker-compose.yml docker-compose.local.yml
	@docker-compose -f $< -f docker-compose.local.yml config > $@
	@echo "${STACK_NAME} stack file created for $@"

.PHONY: ${TEMP_COMPOSE}-letsencrypt
${TEMP_COMPOSE}-letsencrypt: docker-compose.yml docker-compose.letsencrypt.yml
	@docker-compose -f $< -f docker-compose.letsencrypt.yml config > $@
	@echo "${STACK_NAME} stack file created for in $@"

.PHONY: ${TEMP_COMPOSE}-aws
${TEMP_COMPOSE}-aws: docker-compose.yml docker-compose.aws.yml
	@docker-compose -f $< -f docker-compose.aws.yml config > $@
	@echo "${STACK_NAME} stack file created for in $@"

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
	@if [[ ! $$(docker secret ls | grep -w domain.crt) ]]; then docker secret create domain.crt secrets/domain.crt; fi;
	@if [[ ! $$(docker secret ls | grep -w domain.key) ]]; then docker secret create domain.key secrets/domain.key; fi;
	@if [[ ! $$(docker secret ls | grep -w rootca.crt) ]]; then if [ ! -f secrets/rootca.crt ]; then cp secrets/domain.crt secrets/rootca.crt; fi; docker secret create rootca.crt secrets/rootca.crt; fi;
