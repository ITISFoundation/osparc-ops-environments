#
# TODO: not fully windows-friendly (e.g. some tools to install or replace e.g. date, ...  )
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

export VCS_URL:=$(shell git config --get remote.origin.url)
export VCS_REF:=$(shell git rev-parse --short HEAD)
export VCS_STATUS_CLIENT:=$(if $(shell git status -s),'modified/untracked','clean')
export BUILD_DATE:=$(shell date -u +"%Y-%m-%dT%H:%M:%SZ")
export DOCKER_REGISTRY?=itisfoundation

include repo.config

MACHINE_IP = $(shell hostname -I | cut -d' ' -f1)
$(info found host IP to be ${MACHINE_IP})

# TARGETS --------------------------------------------------
.DEFAULT_GOAL := help

.PHONY: help
help: ## This colourful help
	@awk 'BEGIN {FS = ":.*?## "} /^[a-zA-Z_-]+:.*?## / {printf "\033[36m%-20s\033[0m %s\n", $$1, $$2}' $(MAKEFILE_LIST)


.PHONY: venv
# TODO: this is not windows friendly
venv: .venv ## Creates a python virtual environment with dev tools (pip, pylint, ...)
.venv:
	python3 -m venv .venv
	.venv/bin/pip3 install --upgrade pip wheel setuptools
	.venv/bin/pip3 install -r requirements.txt
	@echo "To activate the venv, execute 'source .venv/bin/activate'"



# Misc: info & clean
.PHONY: info
info: ## Displays some parameters of makefile environments (debugging)
	$(info VARIABLES: )
	$(foreach v,                                                                           \
		$(filter-out $(PREDEFINED_VARIABLES) PREDEFINED_VARIABLES, $(sort $(.VARIABLES))), \
		$(info - $(v) = $($(v))  [in $(origin $(v))])                                      \
	)
	# done


.PHONY: clean .check_clean
clean: .check_clean ## Cleans all outputs
	# removing virtual env
	@-rm -rf .venv
	# removing unversioned
	@git clean -dxf -e .vscode/

.check_clean:
	@echo -n "Are you sure? [y/N] " && read ans && [ $${ans:-N} = y ]
	@echo -n "$(shell whoami), are you REALLY sure? [y/N] " && read ans && [ $${ans:-N} = y ]

.PHONY: create-certificates
create-certificates: certificates/domain.crt certificates/domain.key certificates/rootca.crt ## create self-signed certificates and ca authority

.PHONY: install-root-certificate
install-root-certificate: certificates/rootca.crt ## installs a certificate in the host system
	$(info installing certificate in trusted root certificates...)
	$(if $(or $(IS_WIN), $(IS_WSL)), \
		-$(shell certutil.exe -user -addstore -f root $<),\
		$(shell sudo cp $< /usr/local/share/ca-certificates/osparc.crt; sudo update-ca-certificates)\
		)
	$(info restart any browser or docker engine that should use these certificate)

.PHONY: remove-root-certificate
remove-root-certificate: ## removes the certificate from the host system
	$(info deleting certificate from trusted root certificates...)
	$(if $(or $(IS_WIN), $(IS_WSL)), \
		-$(shell certutil.exe -user -delstore -f root "*sparc*"),\
		$(shell sudo rm -f /usr/local/share/ca-certificates/osparc.crt; sudo update-ca-certificates))

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



# FIXME: DO NOT USE... still working on this
.PHONY: autodoc
docs_dir = $(realpath $(CURDIR)/docs)
service_paths =
service_names = $(notdir $(wildcard $(CURDIR)/services/*))
doc_md = $(docs_dir)/stacks-graph-auto.md

autodoc: ## [UNDER DEV] creates diagrams of every stack based on docker-compose files
	mkdir -p $(docs_dir)/img
	# generating a graph of the stack in $(docs_dir)
	@echo "# Stacks\n" >$(doc_md)
	@for service in $(service_names); do    \
		echo "## $$service" >>$(doc_md);  \
		echo "" >>$(doc_md); \
		echo "![](./img/$$service.png)" >>$(doc_md);\
		echo "" >>$(doc_md); \
	done

	@for service in $(service_names); do    \
		docker run --rm -it --name dcv -v $(CURDIR)/services/$$service:/input pmsipilot/docker-compose-viz render -m image; \
		mv $(CURDIR)/services/$$service/docker-compose.png $(docs_dir)/img/$$service.png; \
	done
