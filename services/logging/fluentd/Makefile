.DEFAULT_GOAL := help
STACK_NAME = $(notdir $(shell pwd)/..)
REPO_BASE_DIR := $(shell git rev-parse --show-toplevel)

# TARGETS --------------------------------------------------
include ${REPO_BASE_DIR}/scripts/common.Makefile

build:
	@docker build -t itisfoundation/fluentd:v1.16.9-1.0 .
