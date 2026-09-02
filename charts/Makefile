# to be executed on kubernetes control nodes
REPO_BASE_DIR := $(shell git rev-parse --show-toplevel)

include ${REPO_BASE_DIR}/scripts/common.Makefile
include ${REPO_BASE_DIR}/charts/.tools.Makefile

#
# Vars
#

export CONFIG_DIR := $(shell dirname $(REPO_CONFIG_LOCATION))
CHART_DIRS := $(wildcard $(REPO_BASE_DIR)/charts/*/)

# Note on HELM_DIFF_USE_UPGRADE_DRY_RUN:
# helm-diff renders with `helm template` by default, where `lookup` and API
# capabilities resolve empty - charts using them would show permanent phantom diffs.
# See https://github.com/databus23/helm-diff/issues/253
HELM_DIFF_ENV := HELM_DIFF_USE_UPGRADE_DRY_RUN=true HELM_DIFF_OUTPUT_CONTEXT=5

# Example of usage:
# make helmfile-diff HELMFILE_EXTRA_ARGS='--selector name=traefik'
HELMFILE_EXTRA_ARGS ?=

HELMFILE := $(HELM_DIFF_ENV) helmfile $(HELMFILE_EXTRA_ARGS)

TRIVY_TEMPLATES_DIR := /tmp/rendered-helm-templates

#
# Helpers
#

.PHONY: .helmfile-%
.helmfile-%: .verify-helmfile-installation helmfile.yaml.gotmpl
	set -a; source $(REPO_CONFIG_LOCATION); set +a; \
	$(HELMFILE) -f $(word 2,$^) $*

#
# Artifacts
#

helmfile.yaml.gotmpl: simcore-charts/helmfile.yaml
	cp $(CONFIG_DIR)/$@ $(REPO_BASE_DIR)/charts/helmfile.yaml.gotmpl

simcore-charts/helmfile.yaml: ## Copies the simcore helmfile to the charts directory
	cp $(CONFIG_DIR)/helmfile.simcore.yaml $(REPO_BASE_DIR)/charts/$@

$(TRIVY_TEMPLATES_DIR):
	# generate helm templates for trivy scanning
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

.PHONY: helmfile-destroy
helmfile-destroy: .helmfile-destroy ## Delete the helmfile configuration

.PHONY: trivy-scan
trivy-scan: $(TRIVY_TEMPLATES_DIR) .verify-trivy-installation
trivy-scan: ## Scan rendered helm templates for vulnerabilities
	# Scan templates with trivy
	@trivy config \
		--config-data $(REPO_BASE_DIR)/charts/.trivy-config \
		--ignorefile $(REPO_BASE_DIR)/charts/.trivyignore.yaml \
		--severity MEDIUM,HIGH,CRITICAL \
		--exit-code 1 \
		$(TRIVY_TEMPLATES_DIR)
