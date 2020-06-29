#
# TODO: not fully windows-friendly (e.g. some tools to install or replace e.g. date, ...  )
#
# by sanderegg, pcrespov

PREDEFINED_VARIABLES := $(.VARIABLES)
VERSION := $(shell uname -a)

# Operating system
ifeq ($(filter Windows_NT,$(OS)),)
IS_WSL  := $(if $(findstring microsoft,$(shell uname -a | tr '[:upper:]' '[:lower:]')),WSL,)
IS_OSX  := $(filter Darwin,$(shell uname -a))
IS_LINUX:= $(if $(or $(IS_WSL),$(IS_OSX)),,$(filter Linux,$(shell uname -a)))
endif
IS_WIN  := $(strip $(if $(or $(IS_LINUX),$(IS_OSX),$(IS_WSL)),,$(OS)))
#TODO Simplyify hosts print

$(if $(IS_WIN),$(error Windows is not supported in all recipes. Use WSL instead. Follow instructions in README.txt),)

# Makefile's shell
SHELL := /bin/bash
MAKE_C := $(MAKE) --no-print-directory --directory

# Host machine IP
export MACHINE_IP = $(shell source $(realpath $(CURDIR)/scripts/portable.sh) && get_this_ip)

include repo.config

SERVICES = $(sort $(dir $(wildcard services/*/.)))
# TARGETS --------------------------------------------------
.DEFAULT_GOAL := help

certificates/domain.crt: certificates/domain.key
certificates/domain.key:
	# domain key/crt files must be located in $< and certificates/domain.crt to be used
	@echo -n "No $< certificate detected, do you wish to create self-signed certificates? [y/N] " && read ans && [ $${ans:-N} = y ]; \
	$(MAKE_C) certificates create-certificates; \
	$(MAKE_C) certificates install-root-certificate;

.PHONY: .create-secrets
.create-secrets:
	@$(MAKE_C) certificates deploy

.PHONY: up-local
up-local: .install-fqdn certificates/domain.crt certificates/domain.key .create-secrets ## deploy osparc ops stacks and simcore
	@./scripts/deployments/local-deploy.sh
	@$(MAKE) info-local

.PHONY: up-devel
up-devel: .install-fqdn certificates/domain.crt certificates/domain.key .create-secrets ## deploy osparc ops stacks and simcore
	bash scripts/deployments/local-deploy.sh --devel_mode=1
	@$(MAKE) info-local

.PHONY: up-aws
up-aws:
	./scripts/deployments/aws-deploy.sh


.PHONY: down
down:
	@for service in $(SERVICES); do \
		$(MAKE_C) $$service down; \
	done

.PHONY: leave
leave: ## leaves the swarm
	docker swarm leave -f

.PHONY: .install-fqdn

.install-fqdn:
	@$(if $(IS_WSL), \
		if ! grep -Fq "$(MACHINE_IP) $(MACHINE_FQDN)" /c/Windows/System32/drivers/etc/hosts; then \
		echo -n "Do you wish to install the following host on the Windows host ? [y/N]" && read ans && [ $${ans:-N} = y ] &&  \
		( echo "please run the following in a PWshell with Admin rights:" && \
		echo "Add-Content c:\Windows\System32\drivers\etc\hosts \"\`r\`$(MACHINE_IP) $(MACHINE_FQDN)\`r\`$(MACHINE_IP) $(MONITORING_DOMAIN)\`r\`$(MACHINE_IP) $(REGISTRY_DOMAIN)\`r\`$(MACHINE_IP) $(PORTAINER_DOMAIN)\`r\`$(MACHINE_IP) $(STORAGE_DOMAIN)\`r\`$(MACHINE_IP) $(API_DOMAIN)\"" && \
		echo "OR please run the following in a CMD with Admin rights (note that wildcards are not accepted):" && \
		echo "echo $(MACHINE_IP) $(MACHINE_FQDN) >> c:\Windows\System32\drivers\etc\hosts && echo $(MACHINE_IP) $(MONITORING_DOMAIN) >> c:\Windows\System32\drivers\etc\hosts && echo $(MACHINE_IP) $(PORTAINER_DOMAIN) >> c:\Windows\System32\drivers\etc\hosts && echo $(MACHINE_IP) $(REGISTRY_DOMAIN) >> c:\Windows\System32\drivers\etc\hosts && echo $(MACHINE_IP) $(STORAGE_DOMAIN) >> c:\Windows\System32\drivers\etc\hosts && echo $(MACHINE_IP) $(API_DOMAIN) >> c:\Windows\System32\drivers\etc\hosts") \
		|| true; \
		fi \
	,\
	if ! grep -Fq "$(MACHINE_IP) $(MACHINE_FQDN)" /etc/hosts; then \
		echo -n "Do you wish to install the following hosts? $(MACHINE_IP) $(MACHINE_FQDN) $(MACHINE_IP) $(PORTAINER_DOMAIN) $(MACHINE_IP) $(REGISTRY_DOMAIN) $(MACHINE_IP) $(MONITORING_DOMAIN) $(MACHINE_IP) $(STORAGE_DOMAIN) $(MACHINE_IP) $(API_DOMAIN) [y/N] " && read ans && [ $${ans:-N} = y ] && \
		( sudo printf "$(MACHINE_IP) $(MACHINE_FQDN)\n$(MACHINE_IP) $(PORTAINER_DOMAIN)\n$(MACHINE_IP) $(REGISTRY_DOMAIN)\n$(MACHINE_IP) $(MONITORING_DOMAIN)\n$(MACHINE_IP) $(STORAGE_DOMAIN)\n$(MACHINE_IP) $(API_DOMAIN)\n" | sudo tee -a /etc/hosts && \
		echo "# restarting docker daemon" && \
		sudo systemctl restart docker ) \
		|| true; \
	fi \
	)

	@$(if $(IS_WSL), \
	if ! sudo grep -Fq "$(MACHINE_IP) $(MACHINE_FQDN)" /etc/hosts; then \
		echo -n "Do you wish to install the following host in WSL? \n [y/N] " && read ans && [ $${ans:-N} = y ] && \
		( printf  "Adding\n" && \
		printf "$(MACHINE_IP) $(MACHINE_FQDN)\n$(MACHINE_IP) $(PORTAINER_DOMAIN)\n$(MACHINE_IP) $(REGISTRY_DOMAIN)\n$(MACHINE_IP) $(MONITORING_DOMAIN)\n$(MACHINE_IP) $(STORAGE_DOMAIN)\n$(MACHINE_IP) $(API_DOMAIN)\n" | sudo tee -a /etc/hosts && \
		printf  "to /etc/hosts\n" ) \
		|| true; \
	fi \
	,)

.PHONY: help
help: ## This colourful help
	@awk 'BEGIN {FS = ":.*?## "} /^[a-zA-Z_-]+:.*?## / {printf "\033[36m%-20s\033[0m %s\n", $$1, $$2}' $(MAKEFILE_LIST)


.PHONY: venv
# TODO: this is not windows friendly
venv: .venv ## Creates a python virtual environment with dev tools (pip, pylint, ...)
.venv:
	@python3 -m venv .venv
	@.venv/bin/pip3 install --upgrade pip wheel setuptools
	@.venv/bin/pip3 install -r requirements.txt
	@echo "To activate the venv, execute 'source .venv/bin/activate'"



# Misc: info & clean
.PHONY: info info-vars info-local
info: ## Displays some important info
	$(info - Detected OS : $(IS_LINUX)$(IS_OSX)$(IS_WSL)$(IS_WIN))
	# done

info-vars: ## Displays some parameters of makefile environments (debugging)
	$(info # variables: )
	$(foreach v,                                                                           \
		$(filter-out $(PREDEFINED_VARIABLES) PREDEFINED_VARIABLES, $(sort $(.VARIABLES))), \
		$(info - $(v) = $($(v))  [in $(origin $(v))])                                      \
	)
	# done

info-local: ## Displays the links to the different services e.g. 'make info-local >SITES.md'
	# Links in local mode:
	@echo
	@echo "- https://$(MACHINE_FQDN) (osparc simcore)": framework front-end
	@echo "- https://$(MONITORING_DOMAIN)/portainer/ (portainer)": swarm/containers management
	@echo "- https://$(STORAGE_DOMAIN) (S3 storage)": storage management
	@echo "- https://$(MONITORING_DOMAIN)/grafana (grafana)": monitoring metrics/alerts management
	@echo "- https://$(MONITORING_DOMAIN)/graylog/ (graylog)": aggregated logger
	@echo "- https://$(MONITORING_DOMAIN)/adminer/ (adminer)": postgres adminer
	@echo "- https://$(MONITORING_DOMAIN)/jaeger (jaeger)": jaeger
	@echo "- https://$(MONITORING_DOMAIN)/redis (redis-commander)": access to redis
	@echo ""
	@echo "- https://$(REGISTRY_DOMAIN) (docker registry)": images registry
	@echo "- https://$(MONITORING_DOMAIN)/dashboard/ (traefik)": ui for swarm reverse proxy

.PHONY: clean .check_clean
clean: .check_clean ## Cleans all outputs
	# removing unversioned
	@git clean -dxf -e .vscode/

.check_clean:
	@git clean -ndxf
	@echo -n "Are you sure? [y/N] " && read ans && [ $${ans:-N} = y ]
	@echo -n "$(shell whoami), are you REALLY sure? [y/N] " && read ans && [ $${ans:-N} = y ]


.PHONY: reset-prune
reset-prune: ## resets docker swarm, removes all images, volumes, networks, certificates
	@echo -n "Are you sure ? All volumes (including S3 and the database in local deployment) will be deleted. [y/N] " && read ans && [ $${ans:-N} = y ]
	@echo -n "$(shell whoami), are you REALLY sure? [y/N] " && read ans && [ $${ans:-N} = y ]
	@make down
	@make clean
	-docker system prune -a -f
	-docker volume prune -f
	-docker network prune -f
	-make -C certificates remove-root-certificate
	@make leave


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
