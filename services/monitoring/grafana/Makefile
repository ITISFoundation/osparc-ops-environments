.DEFAULT_GOAL := help
REPO_BASE_DIR := $(abspath $(dir $(abspath $(lastword $(MAKEFILE_LIST))))../../..)
include ${REPO_BASE_DIR}/scripts/common.Makefile



# Internal VARIABLES ------------------------------------------------
TF_STATE_FILE := terraform/.terraform/terraform.tfstate
.PHONY: terraform/main.tf
terraform/main.tf: terraform/main.tf.j2 venv $(REPO_CONFIG_LOCATION)
	# generate $@
	@$(call jinja, $<, $(REPO_CONFIG_LOCATION), $@)

terraform-init: $(TF_STATE_FILE)  ## init terraform

$(TF_STATE_FILE): $(REPO_CONFIG_LOCATION) terraform/main.tf
	# terraform init
	@set -a; source $<; set +a; \
	if [ "$${GRAFANA_TERRAFORM_STATE_BACKEND_TYPE}" = "local" ]; then \
	  terraform -chdir=./terraform init; \
	else \
	  terraform -chdir=./terraform init -backend-config="access_key=$${TF_GRAFANA_STATE_BACKEND_AWS_ACCESS_KEY_ID}" -backend-config="secret_key=$${TF_GRAFANA_STATE_BACKEND_AWS_SECRET_ACCESS_KEY}"; \
	fi

terraform/plan.cache:
	@echo "$@ file not found. Run 'make terraform-plan' to generate it."
	@exit 1

.PHONY: terraform-plan
terraform-plan: $(REPO_CONFIG_LOCATION) $(TF_STATE_FILE) ensure-grafana-online assets ## terraform plan
	# terraform plan
	@set -a; source $<; set +a; \
	terraform -chdir=./terraform plan -out=plan.cache

.PHONY: terraform-apply
terraform-apply: $(REPO_CONFIG_LOCATION) terraform/plan.cache $(TF_STATE_FILE) ensure-grafana-online ## terraform apply
	# terraform apply
	@set -a; source $<; set +a; \
	terraform -chdir=./terraform apply plan.cache

.PHONY: ensure-grafana-online
ensure-grafana-online: $(WAIT_FOR_IT)
	@set -o allexport; \
	source $(REPO_CONFIG_LOCATION); \
	set +o allexport; \
	$(WAIT_FOR_IT) http $$TF_VAR_GRAFANA_URL --timeout=120s --interval=5s --expect-status-code 200

.PHONY: assets
assets: ${REPO_CONFIG_LOCATION}
	@if [ ! -d "$(shell dirname ${REPO_CONFIG_LOCATION})/assets/grafana" ]; then \
		echo "Error: folder does not exist $$GRAFANA_ASSETS_DIR" >&2; \
		exit 1; \
	fi; \
	if [ ! -d "$(shell dirname ${REPO_CONFIG_LOCATION})/../shared/assets/grafana" ]; then \
		echo "Error: folder does not exist $$GRAFANA_COMMON_ASSETS_DIR" >&2; \
		exit 1; \
	fi; \
	rm -rf $(REPO_BASE_DIR)/services/monitoring/grafana/assets || true; \
	mkdir -p $(REPO_BASE_DIR)/services/monitoring/grafana/assets; \
	cp -r $(shell dirname ${REPO_CONFIG_LOCATION})/../shared/assets/grafana $(REPO_BASE_DIR)/services/monitoring/grafana/assets/shared; \
	cp -r $(shell dirname ${REPO_CONFIG_LOCATION})/assets/grafana/* $(REPO_BASE_DIR)/services/monitoring/grafana/assets/shared/;
