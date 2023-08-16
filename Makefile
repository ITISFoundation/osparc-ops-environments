#
#
# by sanderegg, pcrespov, dkaiser
REPO_BASE_DIR := $(shell git rev-parse --show-toplevel)
# TARGETS --------------------------------------------------
include ${REPO_BASE_DIR}/scripts/common.Makefile
include $(REPO_CONFIG_LOCATION)
.DEFAULT_GOAL := help

# Compile list of services
SERVICES = $(sort $(dir $(wildcard services/*/.)))
# TARGETS --------------------------------------------------

certificates/domain.crt: certificates/domain.key

certificates/domain.key:
	# domain key/crt files must be located in $@ and certificates/domain.crt to be used
	@echo -n "No $@ keyfile detected, do you wish to create self-signed certificates? [y/N] " && read ans && [ $${ans:-N} = y ] && \
	$(MAKE_C) certificates create-certificates && \
	$(MAKE_C) certificates install-root-certificate;

.PHONY: .create-secrets
.create-secrets:
	# Creating docker secrets...
	@$(MAKE_C) certificates deploy
	# Done: Creating docker secrets

.PHONY: up-local
up-local: .install-fqdn certificates/domain.crt certificates/domain.key .create-secrets ## deploy osparc ops stacks and simcore, use minio_disabled=1 if minio s3 should not be started (if you have custom S3 set up)
	@bash scripts/deployments/deploy.sh --stack_target=local --minio_enabled=0 --vcs_check=1
	@$(MAKE) info-local

.PHONY: up-vagrant
up-vagrant: .install-fqdn certificates/domain.crt certificates/domain.key .create-secrets ## deploy osparc ops stacks and simcore
	@bash scripts/deployments/deploy.sh --stack_target=vagrant --minio_enabled=0
	@$(MAKE) info-local

.PHONY: up-simcore-aws
up-simcore-aws:  ## Deploy simcores stack only, on AWS
	./scripts/deployments/deploy.sh --stack_target=aws --start_opsstack=1

.PHONY: up-simcore-dalco
up-simcore-dalco:  ## Deploy simcores stack only, on Dalco Cluster
	./scripts/deployments/deploy.sh --stack_target=dalco --start_opsstack=1

.PHONY: up-dalco
up-dalco: ## Deploy ops and simcore stacks on the Dalco Cluster
	./scripts/deployments/deploy.sh --stack_target=dalco --vcs_check=1

.PHONY: up-public
up-public: ## Deploy ops and simcore stacks on the Public Cluster
	./scripts/deployments/deploy.sh --stack_target=public --vcs_check=1

.PHONY: up-aws
up-aws: ## Deploy opt and simcore stacks on the AWS Cluster
	./scripts/deployments/deploy.sh --stack_target=aws --vcs_check=1

.PHONY: up-master
up-master: ## Deploy opt and simcore stacks on the Master Cluster
	./scripts/deployments/deploy.sh --stack_target=master

.PHONY: up-maintenance
up-maintenance: ## Put Osparc into maintenance mode - only team member can access it, display a maintenance page
	@cd services/maintenance-page; \
	make up;


.PHONY: down-maintenance
down-maintenance: ## Stop the maintenance mode
	@cd services/maintenance-page; \
	make down;

.PHONY: down
down: ## Stop all services
	@for service in $(SERVICES); do \
		$(MAKE_C) $$service down; \
	done

.PHONY: down-simcore
down-simcore:  ## Stop the simcore service
	@cd services/deployment-agent; \
	make down;

.PHONY: .install-fqdn
.install-fqdn:
	@$(if $(IS_WSL2), \
		if ! grep -Fq "$(MACHINE_IP) $(MACHINE_FQDN)" /mnt/c/Windows/System32/drivers/etc/hosts; then \
		echo -n "Do you wish to deploy the on a Windows or WSL2 host ? [y/N]" && read ans && [ $${ans:-N} = y ] &&  \
		( echo "Please run the following in a PowerShell with Admin rights, if necessary multiple times, until no error is returned:" && \
		echo "(Get-Content -Path 'C:\Windows\System32\drivers\etc\hosts') | Where-Object { \$$_ -notmatch '^\s*.*\..*\..*\..*\s+.*osparc\.local'} | Set-Content -Path 'C:\Windows\System32\drivers\etc\hosts' -Force; Add-Content c:\Windows\System32\drivers\etc\hosts \"\`r\`$(MACHINE_IP) $(MACHINE_FQDN)\`r\`$(MACHINE_IP) traefikdashboard.$(MACHINE_FQDN)\`r\`$(MACHINE_IP) invitations.$(MACHINE_FQDN)\`r\`$(MACHINE_IP) testing.$(MACHINE_FQDN)\`r\`$(MACHINE_IP) $(MONITORING_DOMAIN)\`r\`$(MACHINE_IP) $(REGISTRY_DOMAIN)\`r\`$(MACHINE_IP) $(STORAGE_DOMAIN)\`r\`$(MACHINE_IP) $(API_DOMAIN)\"") || true; \
		fi \
	,\
	if ! grep -Fq "$(MACHINE_IP) $(MACHINE_FQDN)" /etc/hosts; then \
		echo -n "Do you wish to install the following hosts? $(MACHINE_IP) traefikdashboard.$(MACHINE_FQDN) $(MACHINE_IP) invitations.$(MACHINE_FQDN) $(MACHINE_IP) testing.$(MACHINE_FQDN) $(MACHINE_IP) $(MACHINE_FQDN) $(MACHINE_IP) $(REGISTRY_DOMAIN) $(MACHINE_IP) $(MONITORING_DOMAIN) $(MACHINE_IP) $(STORAGE_DOMAIN) $(MACHINE_IP) $(API_DOMAIN) [y/N] " && read ans && [ $${ans:-N} = y ] && \
		( sudo printf "$(MACHINE_IP) $(MACHINE_FQDN)\n$(MACHINE_IP) traefikdashboard.$(MACHINE_FQDN)\n$(MACHINE_IP) invitations.$(MACHINE_FQDN)\n$(MACHINE_IP) testing.$(MACHINE_FQDN)\n$(MACHINE_IP) $(REGISTRY_DOMAIN)\n$(MACHINE_IP) $(MONITORING_DOMAIN)\n$(MACHINE_IP) $(STORAGE_DOMAIN)\n$(MACHINE_IP) $(API_DOMAIN)\n" | sudo tee -a /etc/hosts && \
		echo "# restarting docker daemon" && \
		sudo systemctl restart docker ) \
		|| true; \
	fi \
	)

	@$(if $(IS_WSL2), \
	if ! sudo grep -Fq "$(MACHINE_IP) $(MACHINE_FQDN)" /etc/hosts; then \
		echo -n "Do you wish to install the following host in WSL? \n [y/N] " && read ans && [ $${ans:-N} = y ] && \
		( printf  "Removing previous entries...\n" $$ \
	    sudo bash -c "sed '/osparc\.local/d' /etc/hosts > /etc/hosts.tmp && cp /etc/hosts.tmp /etc/hosts && rm /etc/hosts.tmp") && \
		( printf  "Adding\n" && \
		printf "$(MACHINE_IP) $(MACHINE_FQDN)\n$(MACHINE_IP) traefikdashboard.$(MACHINE_FQDN)\n$(MACHINE_IP) invitations.$(MACHINE_FQDN)\n$(MACHINE_IP) testing.$(MACHINE_FQDN)\n$(MACHINE_IP) $(REGISTRY_DOMAIN)\n$(MACHINE_IP) $(MONITORING_DOMAIN)\n$(MACHINE_IP) $(STORAGE_DOMAIN)\n$(MACHINE_IP) $(API_DOMAIN)\n" | sudo tee -a /etc/hosts && \
		printf  "to /etc/hosts\n" ) \
		|| true; \
	fi \
	,)


.PHONY: venv
# WARNING: this is not windows friendly
venv: .venv ## Creates a python virtual environment with dev tools (pip, pylint, ...)
.venv:
	@python3 -m venv .venv
	@.venv/bin/pip3 install --upgrade pip wheel setuptools
	@echo "To activate the venv, execute 'source .venv/bin/activate'"

# Misc: info & clean
.PHONY: info info-vars info-local
info: ## Displays some important info
	$(info - Detected OS : $(IS_LINUX)$(IS_OSX)$(IS_WSL)$(IS_WIN))
	# done

info-vars: ## Displays some parameters of makefile environments (debugging)
	$(info # variables: )
	$(foreach v,                                                                           \
		$(filter-out $(PREDEFINED_VARIABLES) PREDEFINED_VARIABLES, $(sort $(.VARIABLES))), \
		$(info - $(v) = $($(v))  [in $(origin $(v))])                                      \
	)
	# done

info-local: ## Displays the links to the different services e.g. 'make info-local >SITES.md'
	# Links in local mode:
	@echo
	@echo "- https://$(MACHINE_FQDN) (osparc simcore)": framework front-end
	@echo "- https://$(MONITORING_DOMAIN)/portainer/ (portainer)": swarm/containers management
	@echo "- https://$(STORAGE_DOMAIN) (S3 storage)": storage management
	@echo "- https://$(MONITORING_DOMAIN)/grafana (grafana)": monitoring metrics/alerts management
	@echo "- https://$(MONITORING_DOMAIN)/graylog/ (graylog)": aggregated logger
	@echo "- https://$(MONITORING_DOMAIN)/adminer/ (adminer)": postgres adminer
	@echo "- https://$(MONITORING_DOMAIN)/jaeger (jaeger)": jaeger
	@echo "- https://$(MONITORING_DOMAIN)/redis (redis-commander)": access to redis
	@echo ""
	@echo "- https://$(REGISTRY_DOMAIN) (docker registry)": images registry
	@echo "- https://$(MONITORING_DOMAIN)/dashboard/ (traefik)": ui for swarm reverse proxy

.PHONY: reset-prune
reset-prune: ## resets docker swarm, removes all images, volumes, secrets, networks, certificates
	@echo -n "Are you sure ? All volumes (including S3 and the database in local deployment) will be deleted. [y/N] " && read ans && [ $${ans:-N} = y ]
	@echo -n "$(shell whoami), are you REALLY sure? [y/N] " && read ans && [ $${ans:-N} = y ]
	@make down
	@make clean
	-docker secret rm $(docker secret ls -q)
	-docker system prune -a -f
	-docker volume prune -f
	-docker network prune -f
	-make -C certificates remove-root-certificate
	@make leave

# via https://stackoverflow.com/questions/42414703/how-to-list-docker-swarm-nodes-with-labels
.PHONY: print-labels
print-labels: ## Print all docker node labels from all nodes (machines)
	@docker node ls -q | xargs docker node inspect \
    -f '{{ .ID }} [{{ .Description.Hostname }}]: {{ .Spec.Labels }}'

#

# RELEASE --------------------------------------------------------------------------------------------------------------------------------------------

_git_origin := $(shell git remote get-url origin)
staging_prefix := staging_
release_prefix := v
_git_get_current_branch = $(shell git rev-parse --abbrev-ref HEAD)
_git_get_formatted_staging_tag = ${staging_prefix}${name}$(version)
_git_get_formatted_release_tag = ${release_prefix}$(version)
_git_list_remote_tags = $(shell git ls-remote --tags origin)

# NOTE: be careful that GNU Make replaces newlines with space which is why this command cannot work using a Make function

.PHONY: release-prod
release-prod: ## Helper to create a staging or production release in Github (usage: make release-prod version=1.2.3)
	@currentDesiredTag=$(_git_get_formatted_release_tag) && \
	if $$(echo $(_git_list_remote_tags) | grep -q "refs/tags/$$currentDesiredTag"); then \
        echo "Tag $$currentDesiredTag is already present on remote"; \
		echo -n "Are you sure you want to retag? This will delete the old tag on the git remote. [y/N] " && read ans && [ $${ans:-N} = y ] && \
		echo -n "$(shell whoami), are you REALLY sure? [y/N] " && read ans && [ $${ans:-N} = y ] && \
		git push --delete $(_git_origin) $$currentDesiredTag && \
		git tag -d $$currentDesiredTag >/dev/null 2>&1 || true && \
		git tag $$currentDesiredTag && \
		git push origin $$currentDesiredTag && \
		echo "Created tag $$currentDesiredTag on git remote $(_git_origin)"; \
    else \
        echo "Tagging git-$(_git_origin)"; \
		git tag -d $$currentDesiredTag >/dev/null 2>&1 || true && \
		git tag $$currentDesiredTag && \
		git push origin $$currentDesiredTag && \
		echo "Created tag $$currentDesiredTag on git remote $(_git_origin)"; \
    fi

.PHONY: release-staging
release-staging:  ## Helper to create a staging or production release in Github (usage: make release-staging name=sprint version=1 )
	@currentDesiredTag=$(_git_get_formatted_staging_tag) && \
	if $$(echo $(_git_list_remote_tags) | grep -q "refs/tags/$$currentDesiredTag"); then \
        echo "Tag $$currentDesiredTag is already present on remote"; \
		echo -n "Are you sure you want to retag? This will delete the old tag on the git remote. [y/N] " && read ans && [ $${ans:-N} = y ] && \
		echo -n "$(shell whoami), are you REALLY sure? [y/N] " && read ans && [ $${ans:-N} = y ] && \
		git push --delete $(_git_origin) $$currentDesiredTag && \
		git tag -d $$currentDesiredTag >/dev/null 2>&1 || true && \
		git tag $$currentDesiredTag && \
		git push origin $$currentDesiredTag && \
		echo "Created tag $$currentDesiredTag on git remote $(_git_origin)"; \
    else \
        echo "Tagging git-$(_git_origin)"; \
		git tag -d $$currentDesiredTag >/dev/null 2>&1 || true && \
		git tag $$currentDesiredTag && \
		git push origin $$currentDesiredTag && \
		echo "Created tag $$currentDesiredTag on git remote $(_git_origin)"; \
    fi
