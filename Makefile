# author: Sylvain Anderegg
VERSION := $(shell uname -a)

export VCS_URL:=$(shell git config --get remote.origin.url)
export VCS_REF:=$(shell git rev-parse --short HEAD)
export VCS_STATUS_CLIENT:=$(if $(shell git status -s),'modified/untracked','clean')
export BUILD_DATE:=$(shell date -u +"%Y-%m-%dT%H:%M:%SZ")
SERVICE_FOLDERS_LIST := services/deployment-agent
export SERVICES_VERSION=1.0.0
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
# Docker build and composition

.PHONY: build build-devel
# target: build, build-devel: – Builds all service images.
build:
	for i in $(SERVICE_FOLDERS_LIST); do \
		cd $$i && ${MAKE} build; \
	done

build-devel:
	for i in $(SERVICE_FOLDERS_LIST); do \
		cd $$i && ${MAKE} build-devel; \
	done


.PHONY: up up-devel
# target: up, up-devel, down: – Starts/Stops services.
up:
	for i in $(SERVICE_FOLDERS_LIST); do \
		cd $$i && ${MAKE} up; \
	done

up-devel:
	for i in $(SERVICE_FOLDERS_LIST); do \
		cd $$i && ${MAKE} up-devel; \
	done

down:
	for i in $(SERVICE_FOLDERS_LIST); do \
		cd $$i && ${MAKE} down; \
	done

.PHONY: push
# target: push: – Pushes services to the registry.
push:
	for i in $(SERVICE_FOLDERS_LIST); do \
		cd $$i && ${MAKE} push; \
	done

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
	@echo '+ SERVICES_VERSION     : ${SERVICES_VERSION}'
	@echo '+ PY_FILES             : $(shell echo $(PY_FILES) | wc -w) files'

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
