# to be executed on kubernetes control nodes
REPO_BASE_DIR := $(shell git rev-parse --show-toplevel)

include ${REPO_BASE_DIR}/scripts/common.Makefile
include ${REPO_BASE_DIR}/charts/.tools.Makefile

#
# Vars
#

export CONFIG_DIR := $(shell dirname $(REPO_CONFIG_LOCATION))
CHART_DIRS := $(wildcard $(REPO_BASE_DIR)/charts/*/)

# Example of usage:
# make helmfile-diff HELMFILE_EXTRA_ARGS='--selector app=adminer'
HELMFILE_EXTRA_ARGS ?=
HELMFILE := helmfile $(HELMFILE_EXTRA_ARGS)

CHART_TEMPLATE_DIR := $(REPO_BASE_DIR)/charts/.template
CHART_TEMPLATES := $(wildcard $(CHART_TEMPLATE_DIR)/*)

TRIVY_TEMPLATES_DIR := /tmp/rendered-helm-templates

#
# Helpers
#

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

$(TRIVY_TEMPLATES_DIR):
	@rm -rf $(TRIVY_TEMPLATES_DIR)
	@$(MAKE) --no-print-directory helmfile-template \
		HELMFILE_EXTRA_ARGS="--output-dir $(TRIVY_TEMPLATES_DIR) --output-dir-template={{.OutputDir}}"

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

.PHONY: trivy-scan
trivy-scan: $(TRIVY_TEMPLATES_DIR) .verify-trivy-installation
trivy-scan: ## Scan rendered helm templates for vulnerabilities
	@trivy config \
		--config-data $(REPO_BASE_DIR)/charts/.trivy-config \
		--ignorefile $(REPO_BASE_DIR)/charts/.trivyignore.yaml \
		--severity MEDIUM,HIGH,CRITICAL \
		--exit-code 1 \
		$(TRIVY_TEMPLATES_DIR)
