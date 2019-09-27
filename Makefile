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
