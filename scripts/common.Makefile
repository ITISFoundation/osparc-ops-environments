# HELPER Makefile that countains all the recipe that will be used by every services. Please include it in your Makefile if you add a new service
SHELL := /bin/bash
MAKE_C := $(MAKE) --no-print-directory --directory
PREDEFINED_VARIABLES := $(.VARIABLES)
VERSION := $(shell uname -a)
SWARM_HOSTS = $(shell docker node ls --format={{.Hostname}} 2>/dev/null)


# Checks for handling various operating systems
ifeq ($(filter Windows_NT,$(OS)),)
IS_WSL  := $(if $(findstring microsoft,$(shell uname -a | tr '[:upper:]' '[:lower:]')),WSL,)
IS_WSL2 := $(if $(findstring -microsoft-,$(shell uname -a)),WSL2,)
IS_OSX  := $(filter Darwin,$(shell uname -a))
IS_LINUX:= $(if $(or $(IS_WSL),$(IS_OSX)),,$(filter Linux,$(shell uname -a)))
endif
IS_WIN  := $(strip $(if $(or $(IS_LINUX),$(IS_OSX),$(IS_WSL)),,$(OS)))

$(if $(IS_WIN),$(error Windows is not supported in all recipes. Use WSL2 instead. Follow instructions in README.md),)
$(if $(IS_WSL2),,$(if $(IS_WSL),$(error WSL1 is not supported in all recipes. Use WSL2 instead. Follow instructions in README.md),))



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


# Check that a valid location to a config file is set.
REPO_BASE_DIR := $(shell git rev-parse --show-toplevel)
export REPO_CONFIG_LOCATION := $(shell cat $(REPO_BASE_DIR)/.config.location)
$(if $(REPO_CONFIG_LOCATION),,$(error The location of the repo.config file given in .config.location is invalid. Aborting))
$(if $(shell cat $(REPO_CONFIG_LOCATION)),,$(error The location of the repo.config file given in .config.location is invalid. Aborting))
$(if $(shell wc -l $(REPO_BASE_DIR)/.config.location | grep 1),,$(error The .config.location file has more than one path specified. Only one path is allowed. Aborting))


ifeq ($(_yq),)
_yq = docker run --rm -i -v ${PWD}:/workdir mikefarah/yq:4.30.4
endif

ifeq ($(_tree),)
_tree = docker run --rm -i -v ${PWD}:${PWD} iankoulski/tree
endif


# Parse the different FQDNS in the repo.config (REPO_CONFIG_LOCATION) and convert them into traefik typo and add the service rule
export DEPLOYMENT_FQDNS_CAPTURE_TRAEFIK_RULE_CATCHALL=$(shell set -o allexport; \
	source $(REPO_CONFIG_LOCATION); \
	if [ -z "$${DEPLOYMENT_FQDNS}" ]; then \
		DEPLOYMENT_FQDNS_CAPTURE_TRAEFIK_RULE_CATCHALL="(Host(\`$$MACHINE_FQDN\`) && PathPrefix(\`/\`)) || (Host(\`invitations.${MACHINE_FQDN}\`)) || (HostRegexp(\`services.$$MACHINE_FQDN\`,\`{subhost:[a-zA-Z0-9-]+}.services.$$MACHINE_FQDN\`) && PathPrefix(\`/\`)) || (HostRegexp(\`services.testing.$$MACHINE_FQDN\`,\`{subhost:[a-zA-Z0-9-]+}.services.testing.$$MACHINE_FQDN\`) && PathPrefix(\`/\`))"; \
	else \
		IFS=', ' read -r -a hosts <<< "$${DEPLOYMENT_FQDNS}"; \
		DEPLOYMENT_FQDNS_CAPTURE_TRAEFIK_RULE_CATCHALL="(Host(\`$$MACHINE_FQDN\`) && PathPrefix(\`/\`)) || (Host(\`invitations.${MACHINE_FQDN}\`)) || (HostRegexp(\`services.$$MACHINE_FQDN\`,\`{subhost:[a-zA-Z0-9-]+}.services.$$MACHINE_FQDN\`) && PathPrefix(\`/\`)) || (HostRegexp(\`services.testing.$$MACHINE_FQDN\`,\`{subhost:[a-zA-Z0-9-]+}.services.testing.$$MACHINE_FQDN\`) && PathPrefix(\`/\`))"; \
		for element in "$${hosts[@]}"; \
		do \
			DEPLOYMENT_FQDNS_CAPTURE_TRAEFIK_RULE_CATCHALL="$$DEPLOYMENT_FQDNS_CAPTURE_TRAEFIK_RULE_CATCHALL || (Host(\`$$element\`) && PathPrefix(\`/\`)) || (Host(\`invitations.$$element\`)) || (HostRegexp(\`services.$$element\`,\`{subhost:[a-zA-Z0-9-]+}.services.$$element\`) && PathPrefix(\`/\`)) || (HostRegexp(\`services.testing.$$element\`,\`{subhost:[a-zA-Z0-9-]+}.services.testing.$$element\`) && PathPrefix(\`/\`))";\
		done; \
		DEPLOYMENT_FQDNS_CAPTURE_TRAEFIK_RULE_CATCHALL="$$DEPLOYMENT_FQDNS_CAPTURE_TRAEFIK_RULE_CATCHALL"; \
	fi; \
	echo $$DEPLOYMENT_FQDNS_CAPTURE_TRAEFIK_RULE_CATCHALL; \
	set +o allexport; )

export DEPLOYMENT_FQDNS_CAPTURE_TRAEFIK_RULE_MAINTENANCE_PAGE=$(shell set -o allexport; \
	source $(REPO_CONFIG_LOCATION); \
	if [ -z "$${DEPLOYMENT_FQDNS}" ]; then \
		DEPLOYMENT_FQDNS_CAPTURE_TRAEFIK_RULE_MAINTENANCE_PAGE="(Host(\`$$MACHINE_FQDN\`) && PathPrefix(\`/\`)) || (HostRegexp(\`services.$$MACHINE_FQDN\`,\`{subhost:[a-zA-Z0-9-]+}.services.$$MACHINE_FQDN\`) && PathPrefix(\`/\`))"; \
	else \
		IFS=', ' read -r -a hosts <<< "$${DEPLOYMENT_FQDNS}"; \
		DEPLOYMENT_FQDNS_CAPTURE_TRAEFIK_RULE_MAINTENANCE_PAGE="(Host(\`$$MACHINE_FQDN\`) && PathPrefix(\`/\`)) || (HostRegexp(\`services.$$MACHINE_FQDN\`,\`{subhost:[a-zA-Z0-9-]+}.services.$$MACHINE_FQDN\`) && PathPrefix(\`/\`))"; \
		for element in "$${hosts[@]}"; \
		do \
			DEPLOYMENT_FQDNS_CAPTURE_TRAEFIK_RULE_MAINTENANCE_PAGE="$$DEPLOYMENT_FQDNS_CAPTURE_TRAEFIK_RULE_MAINTENANCE_PAGE || (Host(\`$$element\`) && PathPrefix(\`/\`)) || (HostRegexp(\`services.$$element\`,\`{subhost:[a-zA-Z0-9-]+}.services.$$element\`) && PathPrefix(\`/\`))";\
		done; \
		DEPLOYMENT_FQDNS_CAPTURE_TRAEFIK_RULE_MAINTENANCE_PAGE="$$DEPLOYMENT_FQDNS_CAPTURE_TRAEFIK_RULE_MAINTENANCE_PAGE"; \
	fi; \
	echo $$DEPLOYMENT_FQDNS_CAPTURE_TRAEFIK_RULE_MAINTENANCE_PAGE; \
	set +o allexport; )

export DEPLOYMENT_FQDNS_TESTING_CAPTURE_TRAEFIK_RULE=$(shell set -o allexport; \
	source $(REPO_CONFIG_LOCATION); \
	if [ -z "$${DEPLOYMENT_FQDNS}" ]; then \
		DEPLOYMENT_FQDNS_TESTING_CAPTURE_TRAEFIK_RULE="(Host(\`testing.$$MACHINE_FQDN\`) && PathPrefix(\`/\`))"; \
	else \
		IFS=', ' read -r -a hosts <<< "$${DEPLOYMENT_FQDNS}"; \
		DEPLOYMENT_FQDNS_TESTING_CAPTURE_TRAEFIK_RULE="(Host(\`testing.$$MACHINE_FQDN\`) && PathPrefix(\`/\`))"; \
		for element in "$${hosts[@]}"; \
		do \
			DEPLOYMENT_FQDNS_TESTING_CAPTURE_TRAEFIK_RULE="$$DEPLOYMENT_FQDNS_TESTING_CAPTURE_TRAEFIK_RULE || (Host(\`testing.$$element\`) && PathPrefix(\`/\`))";\
		done; \
		DEPLOYMENT_FQDNS_TESTING_CAPTURE_TRAEFIK_RULE="$$DEPLOYMENT_FQDNS_TESTING_CAPTURE_TRAEFIK_RULE"; \
	fi; \
	echo $$DEPLOYMENT_FQDNS_TESTING_CAPTURE_TRAEFIK_RULE; \
	set +o allexport; )


# Parse the different FQDNS in repo.config and convert them into traefik typo for APIs subdomains
export DEPLOYMENT_API_DOMAIN_CAPTURE_TRAEFIK_RULE=$(shell set -o allexport; \
	source $(REPO_CONFIG_LOCATION); \
	DEPLOYMENT_API_DOMAIN_CAPTURE_TRAEFIK_RULE="Host(\`$$API_DOMAIN\`) && PathPrefix(\`/\`)"; \
	if [ ! -z "$${DEPLOYMENT_FQDNS}" ]; then \
		IFS=', ' read -r -a hosts <<< "$${DEPLOYMENT_FQDNS}"; \
		count=0; \
		for element in "$${hosts[@]}"; \
		do \
			DEPLOYMENT_API_DOMAIN_CAPTURE_TRAEFIK_RULE="$$DEPLOYMENT_API_DOMAIN_CAPTURE_TRAEFIK_RULE || Host(\`api.$$element\`) && PathPrefix(\`/\`)";\
		done; \
	fi; \
	echo $$DEPLOYMENT_API_DOMAIN_CAPTURE_TRAEFIK_RULE; \
	set +o allexport; )

# Parse the different FQDNS in repo.config and convert them into traefik typo for APIs subdomains
export DEPLOYMENT_API_DOMAIN_TESTING_CAPTURE_TRAEFIK_RULE=$(shell set -o allexport; \
	source $(REPO_CONFIG_LOCATION); \
	DEPLOYMENT_API_DOMAIN_TESTING_CAPTURE_TRAEFIK_RULE="Host(\`testing.$$API_DOMAIN\`) && PathPrefix(\`/\`)"; \
	if [ ! -z "$${DEPLOYMENT_FQDNS}" ]; then \
		IFS=', ' read -r -a hosts <<< "$${DEPLOYMENT_FQDNS}"; \
		count=0; \
		for element in "$${hosts[@]}"; \
		do \
			DEPLOYMENT_API_DOMAIN_TESTING_CAPTURE_TRAEFIK_RULE="$$DEPLOYMENT_API_DOMAIN_TESTING_CAPTURE_TRAEFIK_RULE || Host(\`api.testing.$$element\`) && PathPrefix(\`/\`)";\
		done; \
	fi; \
	echo $$DEPLOYMENT_API_DOMAIN_TESTING_CAPTURE_TRAEFIK_RULE; \
	set +o allexport; )

# Determine host machine IP
export MACHINE_IP = $(shell source $(realpath $(REPO_BASE_DIR)/scripts/portable.sh) && get_this_private_ip)

# Docker secret ID for self-signed cert deplyent
export DIRECTOR_SELF_SIGNED_SSL_SECRET_ID = $(shell if ! docker secret ls | grep -w rootca.crt >/dev/null; then echo VAR_NOT_SET; else docker secret ls | grep rootca.crt | cut -d " " -f1; fi;)

# Generate hashed traefik password
export TRAEFIK_PASSWORD=$(shell source $(REPO_CONFIG_LOCATION); docker run --rm --entrypoint htpasswd registry:2.6 -nb "$$SERVICES_USER" "$$SERVICES_PASSWORD" | cut -d ':' -f2)

.PHONY: help
# thanks to https://marmelab.com/blog/2016/02/29/auto-documented-makefile.html
help:
	@echo "usage: make [target] ..."
	@echo ""
	@echo "Targets for '$(notdir $(REPO_BASE_DIR))':"
	@echo ""
	@awk --posix 'BEGIN {FS = ":.*?## "} /^[[:alpha:][:space:]_-]+:.*?## / {printf "\033[36m%-20s\033[0m %s\n", $$1, $$2}' $(MAKEFILE_LIST)
	@echo ""

.PHONY: down-default
down-default: ## Removes the stack from the swarm
	@echo "${STACK_NAME}"
	@docker stack rm ${STACK_NAME}

.PHONY: leave
leave: ## Leaves swarm stopping all services in it
	-@docker swarm leave -f

.PHONY: clean-default .check_clean
clean-default: .check_clean ## Cleans all outputs
	# cleaning unversioned files in $(REPO_BASE_DIR)
	@git clean -dxf -e .vscode/ -e .config.location

.check_clean:
	@git clean -ndxf
	@echo -n "Are you sure? [y/N] " && read ans && [ $${ans:-N} = y ]
	@echo -n "$(shell whoami), are you REALLY sure? [y/N] " && read ans && [ $${ans:-N} = y ]

.PHONY: .env-default
.env-default: template.env $(REPO_CONFIG_LOCATION)
	@set -o allexport; \
	source $(REPO_CONFIG_LOCATION); \
	export DEPLOYMENT_API_DOMAIN_CAPTURE_TRAEFIK_RULE='${DEPLOYMENT_API_DOMAIN_CAPTURE_TRAEFIK_RULE}'; \
	export DEPLOYMENT_FQDNS_CAPTURE_TRAEFIK_RULE_CATCHALL='${DEPLOYMENT_FQDNS_CAPTURE_TRAEFIK_RULE_CATCHALL}'; \
	export DEPLOYMENT_FQDNS_TESTING_CAPTURE_TRAEFIK_RULE='${DEPLOYMENT_FQDNS_TESTING_CAPTURE_TRAEFIK_RULE}'; \
	export DEPLOYMENT_API_DOMAIN_TESTING_CAPTURE_TRAEFIK_RULE='${DEPLOYMENT_API_DOMAIN_TESTING_CAPTURE_TRAEFIK_RULE}'; \
	export DOLLAR='$$'; \
	set +o allexport; \
	envsubst < $< > .env


# Helpers -------------------------------------------------
.PHONY: .init
.init: ## initializeds swarm cluster
	@$(if $(SWARM_HOSTS),  \
		,                 \
		echo "SWARM IS NOT INITIALIZED. ABORTING! (Tip to solve this: Run `docker swarm init` and create a swarm) " && exit 1\
	)
	@$(if $(filter $(PUBLIC_NETWORK), $(shell docker network ls --format="{{.Name}}")) \
		,  \
		, docker network create --attachable --driver=overlay --subnet=10.10.0.0/16 $(PUBLIC_NETWORK) \
	)
	@$(if $(filter $(MONITORED_NETWORK), $(shell docker network ls --format="{{.Name}}")) \
		,  \
		, docker network create --attachable --driver=overlay --subnet=10.11.0.0/16 $(MONITORED_NETWORK) \
	)


# Gracefully use defaults and potentially overwrite them, via https://stackoverflow.com/a/49804748
%:  %-default
	@ true
