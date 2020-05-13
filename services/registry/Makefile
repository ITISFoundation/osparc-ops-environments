.DEFAULT_GOAL := help

# Operating system
ifeq ($(filter Windows_NT,$(OS)),)
IS_WSL  := $(if $(findstring Microsoft,$(shell uname -a)),WSL,)
IS_OSX  := $(filter Darwin,$(shell uname -a))
IS_LINUX:= $(if $(or $(IS_WSL),$(IS_OSX)),,$(filter Linux,$(shell uname -a)))
endif
IS_WIN  := $(strip $(if $(or $(IS_LINUX),$(IS_OSX),$(IS_WSL)),,$(OS)))

# Makefile's shell
SHELL := $(if $(IS_WIN),powershell.exe,/bin/bash)



# Internal VARIABLES ------------------------------------------------
# STACK_NAME defaults to name of the current directory. Should not to be changed if you follow GitOps operating procedures.
STACK_NAME = $(notdir $(shell pwd))
SWARM_HOSTS = $(shell docker node ls --format={{.Hostname}} 2>/dev/null)
TEMP_COMPOSE=.stack.${STACK_NAME}.yaml


# External VARIABLES
$(if $(wildcard .env), , $(shell cp .env.config .env))
include .env

# exports
# Host machine IP
export MACHINE_IP = $(shell source $(realpath $(CURDIR)/../../scripts/portable.sh) && get_this_ip)

# TARGETS --------------------------------------------------
include $(realpath $(CURDIR)/../../scripts/common.mk)

# Makefile including function used by every services
include ../Makefile


.PHONY: up
up: .init .env ${TEMP_COMPOSE}  ## Deploys registry stack
	docker stack deploy -c ${TEMP_COMPOSE} ${STACK_NAME}

.PHONY: up-letsencrypt
up-letsencrypt: .init .env ${TEMP_COMPOSE}-letsencrypt  ## Deploys registry stack using let's encrypt
	# creating bucket
	# @$(create-s3-bucket)
	docker stack deploy -c ${TEMP_COMPOSE}-letsencrypt ${STACK_NAME}

.PHONY: up-aws
up-aws: .env ${TEMP_COMPOSE}-aws  ## Deploys registry on AWS
	docker stack deploy -c ${TEMP_COMPOSE}-aws ${STACK_NAME}


# Helpers -------------------------------------------------

.PHONY: ${TEMP_COMPOSE}
${TEMP_COMPOSE}: docker-compose.yml docker-compose.self-signed.yml
	@docker-compose -f $< -f docker-compose.self-signed.yml config > $@
	@echo "${STACK_NAME} stack file created for $@"

.PHONY: ${TEMP_COMPOSE}-letsencrypt
${TEMP_COMPOSE}-letsencrypt: docker-compose.yml docker-compose.letsencrypt.yml
	@docker-compose -f $< -f docker-compose.letsencrypt.yml config > $@
	@echo "${STACK_NAME} stack file created for in $@"

.PHONY: ${TEMP_COMPOSE}-aws
${TEMP_COMPOSE}-aws: docker-compose.yml docker-compose.aws.yml
	@docker-compose -f $< -f docker-compose.aws.yml config > $@
	@echo "${STACK_NAME} stack file created for in $@"

