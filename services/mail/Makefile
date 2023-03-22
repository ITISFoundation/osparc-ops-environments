.DEFAULT_GOAL := help


# Internal VARIABLES ------------------------------------------------
# STACK_NAME defaults to name of the current directory. Should not to be changed if you follow GitOps operating procedures.
STACK_NAME = $(notdir $(shell pwd))
SWARM_HOSTS = $(shell docker node ls --format={{.Hostname}} 2>/dev/null)
REPO_BASE_DIR := $(shell git rev-parse --show-toplevel)
TEMP_COMPOSE=.stack.${STACK_NAME}.yaml


# TARGETS --------------------------------------------------
include ${REPO_BASE_DIR}/scripts/common.Makefile

.PHONY: up
up: .env configure ${TEMP_COMPOSE}  ## Deploys mail stack
	docker stack deploy --with-registry-auth --prune --compose-file ${TEMP_COMPOSE} ${STACK_NAME}

.PHONY: up-dalco ## Deploys mail stack for Dalco Cluster
up-dalco: up

.PHONY: up-aws
up-aws: .env configure ${TEMP_COMPOSE}-aws  ## Deploys mail stack in aws
	docker stack deploy --with-registry-auth --prune --compose-file ${TEMP_COMPOSE}-aws ${STACK_NAME}

.PHONY: up-master ## Deploys mail stack for Master Cluster
up-master: up-dalco

.PHONY: up-local ## Deploys mail stack for Local Machine Deployment
up-local: .env configure ${TEMP_COMPOSE}-local
	docker stack deploy --with-registry-auth --prune --compose-file ${TEMP_COMPOSE}-local ${STACK_NAME}

# Helpers -------------------------------------------------

.PHONY: ${TEMP_COMPOSE}
${TEMP_COMPOSE}: docker-compose.yml
	@${REPO_BASE_DIR}/scripts/docker-compose-config.bash $< > $@

.PHONY: ${TEMP_COMPOSE}-aws
${TEMP_COMPOSE}-aws: docker-compose.yml docker-compose.aws.yml
	@${REPO_BASE_DIR}/scripts/docker-compose-config.bash $< docker-compose.aws.yml > $@

.PHONY: ${TEMP_COMPOSE}-local
${TEMP_COMPOSE}-local: docker-compose.yml docker-compose.local.yml
	@${REPO_BASE_DIR}/scripts/docker-compose-config.bash $< docker-compose.local.yml > $@


.PHONY : configure
configure: ## If it does not exist, add the configuration (create mails and alias, and add amavis config) to the mail service
	@if [ -f "config/postfix-accounts.cf" ] ; then \
		echo "Config already created for mail..."; \
	else \
		set -o allexport; \
		source $(REPO_CONFIG_LOCATION); \
		set +o allexport; \
		set -x; \
		echo "Adding configuration for $${SMTP_USERNAME}"; \
		bash setup.sh -i docker.io/mailserver/docker-mailserver:11.2.0 email add $${SMTP_USERNAME} $${SMTP_PASSWORD} && \
		bash setup.sh -i docker.io/mailserver/docker-mailserver:11.2.0 email add root@$${MACHINE_FQDN} $${SMTP_PASSWORD} && \
		bash setup.sh -i docker.io/mailserver/docker-mailserver:11.2.0 email add devops@$${MACHINE_FQDN} $${SMTP_PASSWORD} && \
		bash setup.sh -i docker.io/mailserver/docker-mailserver:11.2.0 email add code-of-conduct@$${MACHINE_FQDN} $${SMTP_PASSWORD} && \
		bash setup.sh -i docker.io/mailserver/docker-mailserver:11.2.0 email add postmaster@$${MACHINE_FQDN} $${SMTP_PASSWORD} && \
		bash setup.sh -i docker.io/mailserver/docker-mailserver:11.2.0 email add s4l-lite@$${MACHINE_FQDN} $${SMTP_PASSWORD} && \
		bash setup.sh -i docker.io/mailserver/docker-mailserver:11.2.0 email add e2e@$${MACHINE_FQDN} $${SMTP_PASSWORD} && \
		bash setup.sh -i docker.io/mailserver/docker-mailserver:11.2.0 email add mailservertestingroute@$${MACHINE_FQDN} $${SMTP_PASSWORD} && \
		bash setup.sh -i docker.io/mailserver/docker-mailserver:11.2.0 alias add root@$${MACHINE_FQDN} $${OSPARC_DEVOPS_MAIL_ADRESS} && \
		bash setup.sh -i docker.io/mailserver/docker-mailserver:11.2.0 alias add support@$${MACHINE_FQDN} $${OSPARC_SUPPORT_MAIL_ADRESS} && \
		bash setup.sh -i docker.io/mailserver/docker-mailserver:11.2.0 alias add devops@$${MACHINE_FQDN} $${OSPARC_DEVOPS_MAIL_ADRESS} && \
		bash setup.sh -i docker.io/mailserver/docker-mailserver:11.2.0 alias add code-of-conduct@$${MACHINE_FQDN} $${OSPARC_SUPPORT_MAIL_ADRESS} && \
		bash setup.sh -i docker.io/mailserver/docker-mailserver:11.2.0 alias add s4l-lite@$${MACHINE_FQDN} $${OSPARC_SUPPORT_MAIL_ADRESS} && \
		bash setup.sh -i docker.io/mailserver/docker-mailserver:11.2.0 alias add postmaster@$${MACHINE_FQDN} $${OSPARC_DEVOPS_MAIL_ADRESS} && \
		bash setup.sh -i docker.io/mailserver/docker-mailserver:11.2.0 alias add mailservertestingroute@$${MACHINE_FQDN} $${MAILSERVER_TESTING_REDIRECT} && \
		bash setup.sh -i docker.io/mailserver/docker-mailserver:11.2.0 alias add e2e@$${MACHINE_FQDN} $${OSPARC_DEVOPS_MAIL_ADRESS}; \
	fi;
