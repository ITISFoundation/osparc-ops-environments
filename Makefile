# author: Sylvain Anderegg
VERSION := $(shell uname -a)

export VCS_URL:=$(shell git config --get remote.origin.url)
export VCS_REF:=$(shell git rev-parse --short HEAD)
export VCS_STATUS_CLIENT:=$(if $(shell git status -s),'modified/untracked','clean')
export BUILD_DATE:=$(shell date -u +"%Y-%m-%dT%H:%M:%SZ")
export DOCKER_REGISTRY=itisfoundation

## Tools ------------------------------------------------------------------------------------------------------
#
tools =

ifeq ($(shell uname -s),Darwin)
	SED = gsed
else
	SED = sed
endif

ifeq ($(shell which ${SED}),)
	tools += $(SED)
endif


## ------------------------------------------------------------------------------------------------------
.PHONY: all
all: help info
ifdef tools
	$(error "Can't find tools:${tools}")
endif


## -------------------------------
# Tools

.PHONY: info
# target: info – Displays some parameters of makefile environments
info:
	@echo '+ VCS_* '
	@echo '  - ULR                : ${VCS_URL}'
	@echo '  - REF                : ${VCS_REF}'
	@echo '  - (STATUS)REF_CLIENT : (${VCS_STATUS_CLIENT})'
	@echo '+ BUILD_DATE           : ${BUILD_DATE}'
	@echo '+ VERSION              : ${VERSION}'
	@echo '+ DOCKER_REGISTRY      : ${DOCKER_REGISTRY}'


## -------------------------------
# Virtual Environments
.venv:
# target: .venv – Creates a python virtual environment with dev tools (pip, pylint, ...)
	python3 -m venv .venv
	.venv/bin/pip3 install --upgrade pip wheel setuptools
	.venv/bin/pip3 install pylint autopep8 virtualenv
	@echo "To activate the venv, execute 'source .venv/bin/activate' or '.venv/bin/activate.bat' (WIN)"

## -------------------------------
# Auxiliary targets.

.PHONY: clean
# target: clean – Cleans all unversioned files in project
clean:
	@git clean -dxf -e .vscode/


.PHONY: help
# target: help – Display all callable targets
help:
	@echo "Make targets in osparc-simcore:"
	@echo
	@egrep "^\s*#\s*target\s*:\s*" [Mm]akefile \
	| $(SED) -r "s/^\s*#\s*target\s*:\s*//g"
	@echo
