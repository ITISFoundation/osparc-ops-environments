REPO_BASE_DIR := $(shell git rev-parse --show-toplevel)

include ${REPO_BASE_DIR}/scripts/common.Makefile
include $(REPO_CONFIG_LOCATION)

CONFIG_DIR := $(shell dirname $(REPO_CONFIG_LOCATION))
CHART_DIRS := $(wildcard $(REPO_BASE_DIR)/charts/*/)

.PHONY: .check-helmfile-installed
.check-helmfile-installed: ## Checks if helmfile is installed
	@if ! command -v helmfile >/dev/null 2>&1; then \
			echo "'helmfile' is not installed. Install it to continue ...";\
	fi

helmfile.yaml: simcore-charts/helmfile.yaml ## Copies the helmfile.yaml to the charts directory
	cp $(CONFIG_DIR)/$@ $(REPO_BASE_DIR)/charts/helmfile.yaml

simcore-charts/helmfile.yaml: ## Copies the simcore helmfile to the charts directory
	cp $(CONFIG_DIR)/helmfile.simcore.yaml $(REPO_BASE_DIR)/charts/$@

.PHONY: helmfile-lint
helmfile-lint: .check-helmfile-installed helmfile.yaml ## Lints the helmfile
	set -a; source $(REPO_CONFIG_LOCATION); set +a; \
	helmfile lint

.PHONY: .helmfile-local-post-install
.helmfile-local-post-install: ## Post install steps for local helmfile deployment
	@$(MAKE) -s configure-local-hosts
	@echo "";
	@echo "Cluster has been deployed locally: http://$(MACHINE_FQDN)";
	@echo "    For secure connections self-signed certificates are used.";
	@echo "

.PHONY: helmfile-apply
helmfile-apply: .check-helmfile-installed helmfile.yaml ## Applies the helmfile configuration
	set -a; source $(REPO_CONFIG_LOCATION); set +a; \
	helmfile -f $(REPO_BASE_DIR)/charts/helmfile.yaml apply

	@if [ "$(MACHINE_FQDN)" = "osparc.local" ]; then \
		$(MAKE) -s .helmfile-local-post-install; \
	fi

.PHONY: helmfile-sync
helmfile-sync: .check-helmfile-installed helmfile.yaml ## Syncs the helmfile configuration
	set -a; source $(REPO_CONFIG_LOCATION); set +a; \
	helmfile -f $(REPO_BASE_DIR)/charts/helmfile.yaml sync

	@if [ "$(MACHINE_FQDN)" = "osparc.local" ]; then \
		$(MAKE) -s .helmfile-local-post-install; \
	fi


.PHONY: configure-local-hosts
configure-local-hosts: ## Adds local hosts entries for the machine
	@echo "Adding $(MACHINE_FQDN) hosts to /etc/hosts ..."
	@grep -q '127.0.0.1 k8s.monitoring.$(MACHINE_FQDN)' /etc/hosts || echo '127.0.0.1 k8s.monitoring.$(MACHINE_FQDN)' | sudo tee -a /etc/hosts

.PHONY: helmfile-diff
helmfile-diff: .check-helmfile-installed helmfile.yaml ## Shows the differences that would be applied by helmfile
	@set -a; source $(REPO_CONFIG_LOCATION); set +a; \
	helmfile -f $(REPO_BASE_DIR)/charts/helmfile.yaml diff

.PHONY: helmfile-delete
helmfile-delete: .check-helmfile-installed helmfile.yaml ## Deletes the helmfile configuration
	@set -a; source $(REPO_CONFIG_LOCATION); set +a; \
	helmfile -f $(REPO_BASE_DIR)/charts/helmfile.yaml delete
