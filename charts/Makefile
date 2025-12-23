# to be executed on kubernetes control nodes
REPO_BASE_DIR := $(shell git rev-parse --show-toplevel)

include ${REPO_BASE_DIR}/scripts/common.Makefile
include $(REPO_CONFIG_LOCATION)

#
# Vars
#

export CONFIG_DIR := $(shell dirname $(REPO_CONFIG_LOCATION))
CHART_DIRS := $(wildcard $(REPO_BASE_DIR)/charts/*/)

# Example of usage:
# make helmfile-diff HELMFILE_EXTRA_ARGS='--selector app=adminer'
HELMFILE_EXTRA_ARGS ?=
HELMFILE := helmfile $(HELMFILE_EXTRA_ARGS)

#
# Helpers
#

.PHONY: .check-helmfile-installed
.check-helmfile-installed: ## Checks if helmfile is installed
	@if ! command -v helmfile >/dev/null 2>&1; then \
			echo "'helmfile' is not installed. Install it to continue ...";\
	fi


.PHONY: .helmfile-%
.helmfile-%: .check-helmfile-installed helmfile.yaml
	set -a; source $(REPO_CONFIG_LOCATION); set +a; \
	$(HELMFILE) -f $(REPO_BASE_DIR)/charts/helmfile.yaml $*

#
# Artifacts
#

helmfile.yaml: simcore-charts/helmfile.yaml ## Copies the helmfile.yaml to the charts directory
	cp $(CONFIG_DIR)/$@ $(REPO_BASE_DIR)/charts/helmfile.yaml

simcore-charts/helmfile.yaml: ## Copies the simcore helmfile to the charts directory
	cp $(CONFIG_DIR)/helmfile.simcore.yaml $(REPO_BASE_DIR)/charts/$@

#
# Public / Exposed targets
#

.PHONY: helmfile-lint
helmfile-lint: .helmfile-lint ## Lints apps

.PHONY: helmfile-apply
helmfile-apply: .helmfile-apply ## Deploy apps (if there are changes)

.PHONY: helmfile-template
helmfile-template: .helmfile-template ## Render apps's templates

.PHONY: helmfile-sync
helmfile-sync: .helmfile-sync ## Force deploy apps even if no changes (don't use unless you know what you are doing)

.PHONY: helmfile-diff
helmfile-diff: .helmfile-diff ## Show changes in apps's configuration

.PHONY: helmfile-delete
helmfile-delete: .helmfile-delete ## Deletes the helmfile configuration
