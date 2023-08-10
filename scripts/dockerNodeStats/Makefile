.DEFAULT_GOAL := help


# Internal VARIABLES ------------------------------------------------
# STACK_NAME defaults to name of the current directory. Should not to be changed if you follow GitOps operating procedures.
STACK_NAME = $(notdir $(shell pwd))
REPO_BASE_DIR := $(shell git rev-parse --show-toplevel)

# TARGETS --------------------------------------------------
include ${REPO_BASE_DIR}/scripts/common.Makefile

.PHONY: up
up:  ## Runs docker node stats script
	@docker run -it --rm -v /var/run/docker.sock:/var/run/docker.sock -v $(shell pwd):/outputs local/docker-node-stats:latest

.PHONY: build
build: ## Builds the docker image
	@DOCKER_BUILDKIT=1 docker buildx build -t local/docker-node-stats:latest .
