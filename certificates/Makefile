#
#
# by sanderegg, pcrespov

PREDEFINED_VARIABLES := $(.VARIABLES)
VERSION := $(shell uname -a)

# Operating system
ifeq ($(filter Windows_NT,$(OS)),)
IS_WSL  := $(if $(findstring Microsoft,$(shell uname -a)),WSL,)
IS_OSX  := $(filter Darwin,$(shell uname -a))
IS_LINUX:= $(if $(or $(IS_WSL),$(IS_OSX)),,$(filter Linux,$(shell uname -a)))
endif
IS_WIN  := $(strip $(if $(or $(IS_LINUX),$(IS_OSX),$(IS_WSL)),,$(OS)))
$(info + Detected OS : $(IS_LINUX)$(IS_OSX)$(IS_WSL)$(IS_WIN))
$(if $(IS_WIN),$(error Windows is not supported in all recipes. Use WSL instead. Follow instructions in README.txt),)

# Makefile's shell
SHELL := /bin/bash

include $(CURDIR)/../repo.config

MACHINE_IP = $(shell hostname -I | cut -d' ' -f1)


.DEFAULT_GOAL := help

# CERTIFICATES --------------------------------------------------

.PHONY: create-certificates
create-certificates: rootca.crt domain.crt domain.key ## create self-signed certificates and ca authority

rootca.key:
	# Creating key for authority in $@
	@openssl genrsa -out $@ 2048

rootca.crt: rootca.key
	# Creating certificate for authority in $@ from key $< (10000 days validity)
	@openssl req -x509 -new -nodes -key $< \
		-subj "/C=US/ST=sparc/O=oSparc/CN=IT'IS oSparc" \
		-sha256 -days 10000 -out $@;

extfile.cnf:
	@echo "subjectAltName = DNS:${MACHINE_FQDN}" > $@ #You can use IP:your_IP or DNS:host_name

domain.key:
	# Creating private key
	@openssl genrsa -out $@ 2048

domain.csr: domain.key
	@openssl req -new -key $< -out $@ \
 		-subj "/C=US/ST=sparc/O=oSparc/CN=${MACHINE_FQDN}"

domain.crt: domain.csr rootca.crt rootca.key extfile.cnf
	# Creating private certificate (500 days validity)
	@openssl x509 -req -in domain.csr \
		-CA rootca.crt \
		-extfile extfile.cnf \
		-CAkey rootca.key \
		-CAcreateserial \
		-out domain.crt \
		-days 500 -sha256

.PHONY: install-root-certificate
install-root-certificate: rootca.crt ## installs a certificate in the host system
	# installing certificate in trusted root certificates and restarting docker daemon...
	@$(if $(IS_WSL),                                            \
		certutil.exe -user -addstore -f root $<;				\
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
	,\
		sudo rm -f /usr/local/share/ca-certificates/osparc.crt; \
		sudo update-ca-certificates \
	)

.PHONY: help
help: ## This colourful help
	@awk 'BEGIN {FS = ":.*?## "} /^[a-zA-Z_-]+:.*?## / {printf "\033[36m%-20s\033[0m %s\n", $$1, $$2}' $(MAKEFILE_LIST)

.PHONY: info
info: ## relevant info on certificates
	# host IP
	@echo ${MACHINE_IP}
	# certificates
	@echo $(wildcard *.crt)
	# keys
	@echo $(wildcard *.key)
	# configs
	@echo $(wildcard *.cnf)



info-var: ## Displays some parameters of makefile environments (debugging)
	$(info VARIABLES: )
	$(foreach v,                                                                           \
		$(filter-out $(PREDEFINED_VARIABLES) PREDEFINED_VARIABLES, $(sort $(.VARIABLES))), \
		$(info - $(v) = $($(v))  [in $(origin $(v))])                                      \
	)
	# done

.PHONY: clean .check_clean
clean: .check_clean ## Cleans all outputs
	# removing unversioned
	@git clean -dxf -e .vscode/

.check_clean:
	@git clean -ndxf
	@echo -n "Are you sure? [y/N] " && read ans && [ $${ans:-N} = y ]
	@echo -n "$(shell whoami), are you REALLY sure? [y/N] " && read ans && [ $${ans:-N} = y ]
