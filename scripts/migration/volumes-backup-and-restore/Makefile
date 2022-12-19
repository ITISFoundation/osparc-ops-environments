.DEFAULT_GOAL := help

# Internal VARIABLES ------------------------------------------------
# STACK_NAME defaults to name of the current directory. Should not to be changed if you follow GitOps operating procedures.
STACK_NAME = $(notdir $(shell pwd))
SWARM_HOSTS = $(shell docker node ls --format={{.Hostname}} 2>/dev/null)
REPO_BASE_DIR := $(shell git rev-parse --show-toplevel)

# TARGETS --------------------------------------------------
include ${REPO_BASE_DIR}/scripts/common.Makefile


.PHONY: backup restore clean all_ssh transfer
backup: ## Backup volumes specified in the env file
	@./volume-backup-and-restore.bash backup

restore: ## Restore volumes specified in the env fike
	@./volume-backup-and-restore.bash restore

transfer: ## Transfer volumes saved in /tmp/backup to another host
	@./volume-backup-and-restore.bash transfer

all_ssh: ## Connect to a distant server in ssh, backup the volume and restore it in the local server
	@./volume-backup-and-restore.bash backup_and_restore_ssh
