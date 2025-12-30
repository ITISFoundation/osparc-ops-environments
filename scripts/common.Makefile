# HELPER Makefile that countains all the recipe that will be used by every services. Please include it in your Makefile if you add a new service
SHELL := /bin/bash
MAKE_C := $(MAKE) --no-print-directory --directory
PREDEFINED_VARIABLES := $(.VARIABLES)
VERSION := $(shell uname -a)


# Checks for handling various operating systems
ifeq ($(filter Windows_NT,$(OS)),)
IS_WSL2 := $(if $(findstring -microsoft-,$(shell uname -a)),WSL2,)
IS_OSX  := $(filter Darwin,$(shell uname -a))
IS_LINUX:= $(if $(or $(IS_WSL),$(IS_OSX)),,$(filter Linux,$(shell uname -a)))
endif
IS_WIN  := $(strip $(if $(or $(IS_LINUX),$(IS_OSX),$(IS_WSL)),,$(OS)))

$(if $(IS_WSL2),,$(if $(IS_WSL),$(error WSL1 is not supported in all recipes. Use WSL2 instead. Follow instructions in README.md),))

# Check that a valid location to a config file is set.
REPO_BASE_DIR := $(abspath $(dir $(abspath $(lastword $(MAKEFILE_LIST))))..)
export REPO_CONFIG_LOCATION := $(shell cat $(REPO_BASE_DIR)/.config.location)
$(if $(REPO_CONFIG_LOCATION),,$(error The location of the repo.config file given in .config.location is invalid. Aborting))
$(if $(shell cat $(REPO_CONFIG_LOCATION)),,$(error The location of the repo.config file given in .config.location is invalid. Aborting))
$(if $(shell wc -l $(REPO_BASE_DIR)/.config.location | grep 1),,$(error The .config.location file has more than one path specified. Only one path is allowed. Aborting))

ifeq ($(_yq),)
_yq = docker run --rm -i -v $${PWD}:/workdir mikefarah/yq:4.30.4
endif

ifeq ($(_tree),)
_tree = docker run --rm -i -v $${PWD}:$${PWD} iankoulski/tree
endif


# Parse the different FQDNS in the repo.config (REPO_CONFIG_LOCATION) and convert them into traefik typo and add the service rule
export DEPLOYMENT_FQDNS_CAPTURE_TRAEFIK_RULE_CATCHALL:=$(shell set -o allexport; \
	source $(REPO_CONFIG_LOCATION); \
	if [ -z "$${DEPLOYMENT_FQDNS}" ]; then \
		DEPLOYMENT_FQDNS_CAPTURE_TRAEFIK_RULE_CATCHALL="(Host(\`$$MACHINE_FQDN\`) && PathPrefix(\`/\`)) || (Host(\`invitations.$$MACHINE_FQDN\`)) || (Host(\`storage.$$MACHINE_FQDN\`)) || (HostRegexp(\`services.$$MACHINE_FQDN\`) && PathPrefix(\`/\`)) || (HostRegexp(\`services.testing.$$MACHINE_FQDN\`) && PathPrefix(\`/\`))"; \
	else \
		IFS=', ' read -r -a hosts <<< "$${DEPLOYMENT_FQDNS}"; \
		DEPLOYMENT_FQDNS_CAPTURE_TRAEFIK_RULE_CATCHALL="(Host(\`$$MACHINE_FQDN\`) && PathPrefix(\`/\`)) || (Host(\`invitations.$$MACHINE_FQDN\`)) || (Host(\`storage.$$MACHINE_FQDN\`)) || (HostRegexp(\`services.$$MACHINE_FQDN\`) && PathPrefix(\`/\`)) || (HostRegexp(\`services.testing.$$MACHINE_FQDN\`) && PathPrefix(\`/\`))"; \
		for element in "$${hosts[@]}"; \
		do \
			DEPLOYMENT_FQDNS_CAPTURE_TRAEFIK_RULE_CATCHALL="$$DEPLOYMENT_FQDNS_CAPTURE_TRAEFIK_RULE_CATCHALL || (Host(\`$$element\`) && PathPrefix(\`/\`)) || (Host(\`invitations.$$element\`)) || (HostRegexp(\`services.$$element\`) && PathPrefix(\`/\`)) || (HostRegexp(\`services.testing.$$element\`) && PathPrefix(\`/\`))";\
		done; \
		DEPLOYMENT_FQDNS_CAPTURE_TRAEFIK_RULE_CATCHALL="$$DEPLOYMENT_FQDNS_CAPTURE_TRAEFIK_RULE_CATCHALL"; \
	fi; \
	echo $$DEPLOYMENT_FQDNS_CAPTURE_TRAEFIK_RULE_CATCHALL; \
	set +o allexport; )

export DEPLOYMENT_FQDNS_CAPTURE_INVITATIONS:=$(shell set -o allexport; \
	source $(REPO_CONFIG_LOCATION); \
	if [ -z "$${DEPLOYMENT_FQDNS}" ]; then \
		DEPLOYMENT_FQDNS_CAPTURE_INVITATIONS="(Host(\`invitations.$$MACHINE_FQDN\`))"; \
	else \
		IFS=', ' read -r -a hosts <<< "$${DEPLOYMENT_FQDNS}"; \
		DEPLOYMENT_FQDNS_CAPTURE_INVITATIONS="(Host(\`invitations.$$MACHINE_FQDN\`))"; \
		for element in "$${hosts[@]}"; \
		do \
			DEPLOYMENT_FQDNS_CAPTURE_INVITATIONS="$$DEPLOYMENT_FQDNS_CAPTURE_INVITATIONS || (Host(\`invitations.$$element\`))";\
		done; \
		DEPLOYMENT_FQDNS_CAPTURE_INVITATIONS="$$DEPLOYMENT_FQDNS_CAPTURE_INVITATIONS"; \
	fi; \
	echo $$DEPLOYMENT_FQDNS_CAPTURE_INVITATIONS; \
	set +o allexport; )

export DEPLOYMENT_FQDNS_CAPTURE_STORAGE=$(shell set -o allexport; \
	source $(REPO_CONFIG_LOCATION); \
	if [ -z "$${DEPLOYMENT_FQDNS}" ]; then \
		DEPLOYMENT_FQDNS_CAPTURE_STORAGE="(Host(\`storage.$$MACHINE_FQDN\`))"; \
	else \
		IFS=', ' read -r -a hosts <<< "$${DEPLOYMENT_FQDNS}"; \
		DEPLOYMENT_FQDNS_CAPTURE_STORAGE="(Host(\`storage.$$MACHINE_FQDN\`))"; \
		for element in "$${hosts[@]}"; \
		do \
			DEPLOYMENT_FQDNS_CAPTURE_STORAGE="$$DEPLOYMENT_FQDNS_CAPTURE_STORAGE || (Host(\`storage.$$element\`))";\
		done; \
		DEPLOYMENT_FQDNS_CAPTURE_STORAGE="$$DEPLOYMENT_FQDNS_CAPTURE_STORAGE"; \
	fi; \
	echo $$DEPLOYMENT_FQDNS_CAPTURE_STORAGE; \
	set +o allexport; )

export DEPLOYMENT_FQDNS_CAPTURE_TRAEFIK_RULE_MAINTENANCE_PAGE:=$(shell set -o allexport; \
	source $(REPO_CONFIG_LOCATION); \
	if [ -z "$${DEPLOYMENT_FQDNS}" ]; then \
		DEPLOYMENT_FQDNS_CAPTURE_TRAEFIK_RULE_MAINTENANCE_PAGE="(Host(\`$$MACHINE_FQDN\`) && PathPrefix(\`/\`)) || (HostRegexp(\`services.$$MACHINE_FQDN\`) && PathPrefix(\`/\`))"; \
	else \
		IFS=', ' read -r -a hosts <<< "$${DEPLOYMENT_FQDNS}"; \
		DEPLOYMENT_FQDNS_CAPTURE_TRAEFIK_RULE_MAINTENANCE_PAGE="(Host(\`$$MACHINE_FQDN\`) && PathPrefix(\`/\`)) || (HostRegexp(\`services.$$MACHINE_FQDN\`) && PathPrefix(\`/\`))"; \
		for element in "$${hosts[@]}"; \
		do \
			DEPLOYMENT_FQDNS_CAPTURE_TRAEFIK_RULE_MAINTENANCE_PAGE="$$DEPLOYMENT_FQDNS_CAPTURE_TRAEFIK_RULE_MAINTENANCE_PAGE || (Host(\`$$element\`) && PathPrefix(\`/\`)) || (HostRegexp(\`services.$$element\`) && PathPrefix(\`/\`))";\
		done; \
		DEPLOYMENT_FQDNS_CAPTURE_TRAEFIK_RULE_MAINTENANCE_PAGE="$$DEPLOYMENT_FQDNS_CAPTURE_TRAEFIK_RULE_MAINTENANCE_PAGE"; \
	fi; \
	echo $$DEPLOYMENT_FQDNS_CAPTURE_TRAEFIK_RULE_MAINTENANCE_PAGE; \
	set +o allexport; )

export DEPLOYMENT_FQDNS_TESTING_CAPTURE_TRAEFIK_RULE:=$(shell set -o allexport; \
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

export DEPLOYMENT_FQDNS_WWW_CAPTURE_TRAEFIK_RULE:=$(shell set -o allexport; \
	source $(REPO_CONFIG_LOCATION); \
	if [ -z "$${DEPLOYMENT_FQDNS}" ]; then \
		DEPLOYMENT_FQDNS_WWW_CAPTURE_TRAEFIK_RULE="(Host(\`www.$$MACHINE_FQDN\`) && PathPrefix(\`/\`))"; \
	else \
		IFS=', ' read -r -a hosts <<< "$${DEPLOYMENT_FQDNS}"; \
		DEPLOYMENT_FQDNS_WWW_CAPTURE_TRAEFIK_RULE="(Host(\`www.$$MACHINE_FQDN\`) && PathPrefix(\`/\`))"; \
		for element in "$${hosts[@]}"; \
		do \
			DEPLOYMENT_FQDNS_WWW_CAPTURE_TRAEFIK_RULE="$$DEPLOYMENT_FQDNS_WWW_CAPTURE_TRAEFIK_RULE || (Host(\`www.$$element\`) && PathPrefix(\`/\`))";\
		done; \
		DEPLOYMENT_FQDNS_WWW_CAPTURE_TRAEFIK_RULE="$$DEPLOYMENT_FQDNS_WWW_CAPTURE_TRAEFIK_RULE"; \
	fi; \
	echo $$DEPLOYMENT_FQDNS_WWW_CAPTURE_TRAEFIK_RULE; \
	set +o allexport; )

export DEPLOYMENT_FQDNS_APPMOTION_CAPTURE_TRAEFIK_RULE:=$(shell set -o allexport; \
	source $(REPO_CONFIG_LOCATION); \
	if [ -z "$${DEPLOYMENT_FQDNS}" ]; then \
		DEPLOYMENT_FQDNS_APPMOTION_CAPTURE_TRAEFIK_RULE="(Host(\`pay.$$MACHINE_FQDN\`) && PathPrefix(\`/\`))"; \
	else \
		IFS=', ' read -r -a hosts <<< "$${DEPLOYMENT_FQDNS}"; \
		DEPLOYMENT_FQDNS_APPMOTION_CAPTURE_TRAEFIK_RULE="(Host(\`pay.$$MACHINE_FQDN\`) && PathPrefix(\`/\`))"; \
		for element in "$${hosts[@]}"; \
		do \
			DEPLOYMENT_FQDNS_APPMOTION_CAPTURE_TRAEFIK_RULE="$$DEPLOYMENT_FQDNS_APPMOTION_CAPTURE_TRAEFIK_RULE || (Host(\`pay.$$element\`) && PathPrefix(\`/\`))";\
		done; \
		DEPLOYMENT_FQDNS_APPMOTION_CAPTURE_TRAEFIK_RULE="$$DEPLOYMENT_FQDNS_APPMOTION_CAPTURE_TRAEFIK_RULE"; \
	fi; \
	echo $$DEPLOYMENT_FQDNS_APPMOTION_CAPTURE_TRAEFIK_RULE; \
	set +o allexport; )

# Parse the different FQDNS in repo.config and convert them into traefik typo for APIs subdomains
export DEPLOYMENT_API_DOMAIN_CAPTURE_TRAEFIK_RULE:=$(shell set -o allexport; \
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
export DEPLOYMENT_API_DOMAIN_TESTING_CAPTURE_TRAEFIK_RULE:=$(shell set -o allexport; \
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
export MACHINE_IP:=$(shell source $(realpath $(REPO_BASE_DIR)/scripts/portable.sh) && get_this_private_ip)

# Docker secret ID for self-signed cert deplyent
export DIRECTOR_SELF_SIGNED_SSL_SECRET_ID:=$(shell if ! docker secret ls | grep -w rootca.crt >/dev/null; then echo VAR_NOT_SET; else docker secret ls | grep rootca.crt | cut -d " " -f1; fi;)

# Generate hashed traefik password
export TRAEFIK_PASSWORD:=$(shell source $(REPO_CONFIG_LOCATION); docker run --rm --entrypoint htpasswd registry:2.6 -nb "$$SERVICES_USER" "$$SERVICES_PASSWORD" | cut -d ':' -f2)

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
	export DEPLOYMENT_FQDNS_CAPTURE_INVITATIONS='${DEPLOYMENT_FQDNS_CAPTURE_INVITATIONS}'; \
	export DOLLAR='$$'; \
	$(if $(STACK_NAME),export STACK_NAME='$(STACK_NAME)';) \
	set +o allexport; \
	envsubst < $< > .env

ifdef STACK_NAME

.PHONY: prune-docker-stack-configs-default
prune-docker-stack-configs-default: ## Clean all unused stack configs
	@# Since the introduction of rolling docker config updates old
	@# [docker config] versions are kept. This target removes them
	@# https://github.com/docker/cli/issues/203
	@#
	@# This should be run before stack update in order to
	@# keep previous config version for potential rollback
	@#
	@# This will not clean "external" configs. To achieve this extend
	@# this target in related Makefiles.
	@#
	@# Long live Kubernetes ConfigMaps!

	@for id in $$(docker config ls --filter "label=com.docker.stack.namespace=${STACK_NAME}" --format '{{.ID}}'); do \
	    docker config rm "$$id" >/dev/null 2>&1 || true; \
	done

.PHONY: prune-docker-stack-secrets-default
prune-docker-stack-secrets-default: ## Clean all unused stack secrets
	@# Same as for configs

	@for id in $$(docker secret ls --filter "label=com.docker.stack.namespace=${STACK_NAME}" --format '{{.ID}}'); do \
	    docker secret rm "$$id" >/dev/null 2>&1 || true; \
	done

endif

# Helpers -------------------------------------------------
.PHONY: .init
.init: ## initializeds swarm cluster
	@node_state="$$(docker info --format '{{ .Swarm.LocalNodeState }}')"; \
	if [ "$$node_state" = "inactive" ]; then \
		echo "This node is not in a swarm cluster. In production, use ansible to properly initialize a swarm cluster."; \
		read -p "Do you want to initialize a swarm cluster? (y/n): " answer; \
		if [ "$$answer" = "n" ]; then \
			echo "Swarm initialization canceled. Script cannot proceed without an initialized swarm cluster"; \
			exit 1; \
		fi; \
		echo "Initializing a swarm cluster"; \
		docker swarm init > /dev/null; \
		docker node ls --quiet | xargs -I {} sh -c ' \
			docker node update --label-add simcore=true \
				--label-add dynamicsidecar=true \
				--label-add dasksidecar=true \
				--label-add rabbit=true \
				--label-add redis=true \
				--label-add traefik=true \
				--label-add ops=true \
				--label-add prometheus=true \
			 	--label-add minio=true {}' > /dev/null; \
	fi

# Helpers -------------------------------------------------

# Check that given variables are set and all have non-empty values,
# die with an error otherwise.
#
# Params:
#   1. Variable name(s) to test.
#   2. (optional) Error message to print.
guard-%:
	@ if [ "${${*}}" = "" ]; then \
		echo "Argument '$*' is missing. TIP: make <rule> $*=<value>"; \
		exit 1; \
	fi

# Explicitly define optional arguments
# do nothing target https://stackoverflow.com/a/46648773/12124525
guard-optional-%:
	@:

guard-optional-bool-%:
	@if [ "${${*}}" != "true" ] && [ "${${*}}" != "false" ] && [ "${${*}}" != "" ]; then \
		echo "Argument '${*}' must be 'true', 'false', or empty"; \
		exit 1; \
	fi;

# Gracefully use defaults and potentially overwrite them, via https://stackoverflow.com/a/49804748
%:  %-default
	@ true

#
# Automatic VENV management
#
# Inspired from https://potyarkin.com/posts/2019/manage-python-virtual-environment-from-your-makefile/

VENV_DIR=$(REPO_BASE_DIR)/.venv
VENV_BIN=$(VENV_DIR)/bin

# NOTE: this is because the gitlab CI does not allow to source cargon/env on the fly
UV := $$HOME/.local/bin/uv

$(UV):
	@if [ ! -f $@ ]; then \
		echo "Installing uv..."; \
		curl -LsSf https://astral.sh/uv/install.sh | sh; \
	fi

UVX := $$HOME/.local/bin/uvx
$(UVX): $(UV)

# Use venv for any target that requires virtual environment to be created and configured
venv: $(VENV_DIR)  ## configure repo's virtual environment
$(VENV_BIN): $(VENV_DIR)

$(VENV_DIR): $(UV)
	@if [ ! -d $@ ]; then \
		$< venv $@; \
		VIRTUAL_ENV=$@ $< pip install --upgrade pip wheel setuptools; \
		VIRTUAL_ENV=$@ $< pip install jinjanator typer pre-commit; \
		$(VENV_BIN)/pre-commit install > /dev/null 2>&1; \
		$(UV) self update || true; \
	fi

# Ensure tool is available or fail otherwise
#
# USAGE:
#
#	codestyle: $(VENV_BIN)/pyflakes
#		$(VENV_BIN)/pyflakes .
#
$(VENV_BIN)/%: $(VENV_DIR)
	@if [ ! -f "$@" ]; then \
		echo "ERROR: '$*' is not found in $(VENV_BIN)"; \
		exit 1; \
	fi

.PHONY: show-venv
show-venv: venv  ## show venv info
	@$(VENV_BIN)/python -c "import sys; print('Python ' + sys.version.replace('\n',''))"
	@$(UV) --version
	@echo venv: $(VENV_DIR)

.PHONY: install
install: guard-optional-REQUIREMENTS_FILE venv ## install requirements.txt dependencies
	@if [ -z "$(REQUIREMENTS_FILE)" ]; then \
		REQUIREMENTS_FILE=./requirements.txt; \
	else \
		REQUIREMENTS_FILE=$(REQUIREMENTS_FILE); \
	fi; \
	VIRTUAL_ENV=$(VENV_DIR) $(UV) pip install --requirement $$REQUIREMENTS_FILE

# https://github.com/kolypto/j2cli?tab=readme-ov-file#customization
ifeq ($(shell test -f j2cli_customization.py && echo -n yes),yes)

define jinja
	${VENV_BIN}/j2 --format=env $(1) $(2) -o $(3) \
	--filters $(REPO_BASE_DIR)/scripts/j2cli_global_filters.py \
	--customize j2cli_customization.py \
	--quiet
endef

else

define jinja
	${VENV_BIN}/j2 --quiet --format=env $(1) $(2) -o $(3) \
	--filters $(REPO_BASE_DIR)/scripts/j2cli_global_filters.py \
	--quiet
endef

endif

#
# wait-fot-it functionality
#

WAIT_FOR_IT := $(REPO_BASE_DIR)/scripts/wait4x

alias: $(WAIT_FOR_IT)

# https://github.com/wait4x/wait4x
$(WAIT_FOR_IT):  ## installs wait4x utility for WAIT_FOR_IT functionality
	# installing wait4x
	@mkdir --parents /tmp/wait4x
	@cd /tmp/wait4x && curl --silent --location --remote-name https://github.com/wait4x/wait4x/releases/download/v3.5.0/wait4x-linux-amd64.tar.gz
	@tar -xf /tmp/wait4x/wait4x-linux-amd64.tar.gz -C /tmp/wait4x
	@mv /tmp/wait4x/wait4x $@
	@rm -rf /tmp/wait4x
	@$@ version

# Arguments
# 1 - message to show (e.g. Are you sure?)
# 2 - input to confirm action (e.g. yes)
# 3 - force confirm (e.g. true)
#
# Examples
# $(call confirm_action) -- use with default messages
# $(call confirm_action,Do you want to delete all files?) -- overwrite confirm message
# $(call confirm_action,,,$(CI)) -- ignore in CI (CI := true)
# echo before; $(call confirm_action); echo after -- chain in bash
define confirm_action
	CONFIRM_MSG="$(if $(1),$(1),Are you sure?)"; \
	CONFIRM_KEY="$(if $(2),$(2),yes)"; \
	SKIP_CHECK="$(if $(3),$(3),false)"; \
	if [ "$$SKIP_CHECK" != true ]; then \
		echo "$$CONFIRM_MSG"; \
		read -p "Type '$$CONFIRM_KEY' to confirm: " USER_INPUT; \
		if [ "$$USER_INPUT" != "$$CONFIRM_KEY" ]; then \
			echo "CONFIRM_KEY does not match. Aborted."; \
			exit 1; \
		fi; \
	fi
endef
