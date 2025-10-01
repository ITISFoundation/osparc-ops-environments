# to be executed on kubernetes control nodes
REPO_BASE_DIR := $(shell git rev-parse --show-toplevel)

include ${REPO_BASE_DIR}/scripts/common.Makefile
include $(REPO_CONFIG_LOCATION)

#
# Vars
#

CONFIG_DIR := $(shell dirname $(REPO_CONFIG_LOCATION))
CHART_DIRS := $(wildcard $(REPO_BASE_DIR)/charts/*/)

HELMFILE_EXTRA_ARGS ?=

HELMFILE := helmfile $(HELMFILE_EXTRA_ARGS)

#
# Help Targets
#

.PHONY: .check-helmfile-installed
.check-helmfile-installed: ## Checks if helmfile is installed
	@if ! command -v helmfile >/dev/null 2>&1; then \
			echo "'helmfile' is not installed. Install it to continue ...";\
	fi

#
# Artifacts
#

helmfile.yaml: simcore-charts/helmfile.yaml ## Copies the helmfile.yaml to the charts directory
	cp $(CONFIG_DIR)/$@ $(REPO_BASE_DIR)/charts/helmfile.yaml

simcore-charts/helmfile.yaml: ## Copies the simcore helmfile to the charts directory
	cp $(CONFIG_DIR)/helmfile.simcore.yaml $(REPO_BASE_DIR)/charts/$@

#
# Targets
#

.PHONY: helmfile-lint
helmfile-lint: .check-helmfile-installed helmfile.yaml ## Lints the helmfile
	set -a; source $(REPO_CONFIG_LOCATION); set +a; \
	$(HELMFILE) lint

.PHONY: helmfile-apply
helmfile-apply: .check-helmfile-installed helmfile.yaml ## Applies the helmfile configuration
	set -a; source $(REPO_CONFIG_LOCATION); set +a; \
	$(HELMFILE) -f $(REPO_BASE_DIR)/charts/helmfile.yaml apply

.PHONY: helmfile-sync
helmfile-sync: .check-helmfile-installed helmfile.yaml ## Syncs the helmfile configuration (use `helmfile-apply` to deploy the app)
	set -a; source $(REPO_CONFIG_LOCATION); set +a; \
	$(HELMFILE) -f $(REPO_BASE_DIR)/charts/helmfile.yaml sync

.PHONY: helmfile-diff
helmfile-diff: .check-helmfile-installed helmfile.yaml ## Shows the differences that would be applied by helmfile
	@set -a; source $(REPO_CONFIG_LOCATION); set +a; \
	$(HELMFILE) -f $(REPO_BASE_DIR)/charts/helmfile.yaml diff

.PHONY: helmfile-delete
helmfile-delete: .check-helmfile-installed helmfile.yaml ## Deletes the helmfile configuration
	@set -a; source $(REPO_CONFIG_LOCATION); set +a; \
	$(HELMFILE) -f $(REPO_BASE_DIR)/charts/helmfile.yaml delete
