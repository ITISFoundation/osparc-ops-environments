.DEFAULT_GOAL := help
REPO_BASE_DIR := $(abspath $(dir $(abspath $(lastword $(MAKEFILE_LIST))))../../..)
include ${REPO_BASE_DIR}/scripts/common.Makefile



# Internal VARIABLES ------------------------------------------------
TF_STATE_FILE := terraform/.terraform/terraform.tfstate
.PHONY: terraform/main.tf
terraform/main.tf: terraform/main.tf.j2 .venv $(REPO_CONFIG_LOCATION)
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
ensure-grafana-online:
	@set -o allexport; \
	source $(REPO_CONFIG_LOCATION); \
	set +o allexport; \
	url=$${TF_VAR_GRAFANA_URL}; \
	echo "Waiting for grafana at $$url to become reachable..."; \
	attempts=0; \
	max_attempts=10; \
	while [ $$attempts -lt $$max_attempts ]; do \
		status_code=$$(curl -k -o /dev/null -s -w "%{http_code}" --max-time 10 $$url); \
		if [ "$$status_code" -ge 200 ] && [ "$$status_code" -lt 400 ]; then \
			echo "Grafana is online"; \
			break; \
		else \
			echo "Grafana still unreachable, waiting 5s for grafana to become reachable... (Attempt $$((attempts+1)))"; \
			sleep 5; \
			attempts=$$((attempts + 1)); \
		fi; \
	done; \
	if [ $$attempts -eq $$max_attempts ]; then \
		echo "Max attempts reached, Grafana is still unreachable."; \
		exit 1; \
	fi;

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
