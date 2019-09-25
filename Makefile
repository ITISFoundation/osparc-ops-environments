#
# TODO: not fully windows-friendly (e.g. some tools to install or replace e.g. date, ...  )
#
# by sanderegg, pcrespov

PREDEFINED_VARIABLES := $(.VARIABLES)
VERSION := $(shell uname -a)

export VCS_URL:=$(shell git config --get remote.origin.url)
export VCS_REF:=$(shell git rev-parse --short HEAD)
export VCS_STATUS_CLIENT:=$(if $(shell git status -s),'modified/untracked','clean')
export BUILD_DATE:=$(shell date -u +"%Y-%m-%dT%H:%M:%SZ")
export DOCKER_REGISTRY?=itisfoundation


# TARGETS --------------------------------------------------
.DEFAULT_GOAL := help

.PHONY: help
help: ## This colourful help
	@awk 'BEGIN {FS = ":.*?## "} /^[a-zA-Z_-]+:.*?## / {printf "\033[36m%-20s\033[0m %s\n", $$1, $$2}' $(MAKEFILE_LIST)


.PHONY: info

info: ## Displays some parameters of makefile environments (debugging)
	$(info VARIABLES: )
	$(foreach v,                                                                           \
		$(filter-out $(PREDEFINED_VARIABLES) PREDEFINED_VARIABLES, $(sort $(.VARIABLES))), \
		$(info - $(v) = $($(v))  [in $(origin $(v))])                                      \
	)
	# done


.PHONY: clean check_clean
clean: .check_clean ## Cleans all outputs
	# removing virtual env
	@-rm -rf .venv
	# removing unversioned
	@git clean -dxf -e .vscode/

.check_clean:
	@echo -n "Are you sure? [y/N] " && read ans && [ $${ans:-N} = y ]
	@echo -n "$(shell whoami), are you REALLY sure? [y/N] " && read ans && [ $${ans:-N} = y ]


.PHONY: venv
# TODO: this is not windows friendly
venv: .venv ## creates a python virtual environment with dev tools (pip, pylint, ...)
.venv:
	python3 -m venv .venv
	.venv/bin/pip3 install --upgrade pip wheel setuptools
	.venv/bin/pip3 install -r requirements.txt
	@echo "To activate the venv, execute 'source .venv/bin/activate'"

