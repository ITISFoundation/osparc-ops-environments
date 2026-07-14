# to be executed on kubernetes control nodes
REPO_BASE_DIR := $(shell git rev-parse --show-toplevel)

include ${REPO_BASE_DIR}/scripts/common.Makefile

#
# Vars
#

export CONFIG_DIR := $(shell dirname $(REPO_CONFIG_LOCATION))
CHART_DIRS := $(wildcard $(REPO_BASE_DIR)/charts/*/)


# Helmfile version is dictated by helm version installed in the cluster.
# Kubepsray dictates the helm version to be installed in the cluster.
# Based on helm version choose the highest compatible helmfile version.
# (helmfile defines minimum required helm version)
# NOTE: keep in sync with github workflows and version in running clusters
HELMFILE_EXPECTED_VERSION := 0.165.0

# Example of usage:
# make helmfile-diff HELMFILE_EXTRA_ARGS='--selector app=adminer'
HELMFILE_EXTRA_ARGS ?=
HELMFILE := helmfile $(HELMFILE_EXTRA_ARGS)

CHART_TEMPLATE_DIR := $(REPO_BASE_DIR)/charts/.template
CHART_TEMPLATES := $(wildcard $(CHART_TEMPLATE_DIR)/*)

#
# Helpers
#

.PHONY: .verify-helmfile-installation
.verify-helmfile-installation:
	@if ! command -v helmfile >/dev/null 2>&1; then \
		echo "'helmfile' is not installed. Install version $(HELMFILE_EXPECTED_VERSION) to continue ..."; \
		exit 1; \
	fi
	@if ! helmfile --version | grep -q "$(HELMFILE_EXPECTED_VERSION)"; then \
		echo "WARNING: installed helmfile version does not match"> /dev/stderr; \
		echo "Expected helmfile version:'$(HELMFILE_EXPECTED_VERSION)'" > /dev/stderr; \
		sleep 3s; \
	fi

.PHONY: .helmfile-%
.helmfile-%: .verify-helmfile-installation helmfile.yaml
	set -a; source $(REPO_CONFIG_LOCATION); set +a; \
	$(HELMFILE) -f $(REPO_BASE_DIR)/charts/helmfile.yaml $*

.PHONY: add-new-chart-directory-from-template
add-new-chart-directory-from-template: guard-CHART_NAME venv ## Adds a new chart directory with standard structure
	$(eval CHART_DIR := $(REPO_BASE_DIR)/charts/$(CHART_NAME))
	@mkdir $(CHART_DIR)
	@echo "CHART_NAME=$(CHART_NAME)" > $(CHART_DIR)/.env
	@$(foreach tmpl,$(CHART_TEMPLATES),\
		$(call jinja, $(tmpl), $(CHART_DIR)/.env, $(CHART_DIR)/$(notdir $(tmpl)));\
	)
	@rm $(CHART_DIR)/.env

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

.PHONY: helmfile-apply
helmfile-apply: .helmfile-apply ## Deploy apps (if there are changes)

.PHONY: helmfile-diff
helmfile-diff: .helmfile-diff ## Show changes in apps's configuration

.PHONY: helmfile-template
helmfile-template: .helmfile-template ## Render apps's templates

.PHONY: helmfile-lint
helmfile-lint: .helmfile-lint ## Lint apps

.PHONY: helmfile-sync
helmfile-sync: .helmfile-sync ## Deploy apps even if no changes (don't use unless you know why)

.PHONY: helmfile-delete
helmfile-delete: .helmfile-delete ## Delete the helmfile configuration
