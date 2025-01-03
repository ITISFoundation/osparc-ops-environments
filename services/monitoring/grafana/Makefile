.DEFAULT_GOAL := help
REPO_BASE_DIR := $(shell git rev-parse --show-toplevel)
include ${REPO_BASE_DIR}/scripts/common.Makefile



# Internal VARIABLES ------------------------------------------------
TF_STATE_FILE := terraform/.terraform/terraform.tfstate

terraform/main.tf: terraform/main.tf.j2 .venv $(CI_ENV_FILE)
	# generate $@
	@$(call jinja, $<, $(CI_ENV_FILE), $@)
	# validate and format $@

terraform-init: $(TF_STATE_FILE)  ## init terraform

$(TF_STATE_FILE): $(CI_ENV_FILE) terraform/main.tf
	# terraform init
	@set -a; source $<; set +a; \
	if [ "$${TF_STATE_BACKEND_TYPE}" = "local" ]; then \
	  terraform -chdir=./terraform init; \
	else \
	  terraform -chdir=./terraform init -backend-config="access_key=$${TF_BACKEND_ACCESS_KEY}" -backend-config="secret_key=$${TF_BACKEND_SECRET_KEY}"; \
	fi

terraform/plan.cache:
	@echo "$@ file not found. Run 'make terraform-plan' to generate it."
	@exit 1

.PHONY: terraform-plan
terraform-plan: $(CI_ENV_FILE) $(TF_STATE_FILE) ensure-grafana-online ## terraform plan
	# terraform plan
	@set -a; source $<; source $${REPO_CONFIG_LOCATION}; set +a; \
    TF_VAR_aws_region=$${TF_AWS_REGION} TF_VAR_aws_access_key=$${TF_AWS_ACCESS_KEY_ID} TF_VAR_aws_secret_key=$${TF_AWS_SECRET_ACCESS_KEY} terraform -chdir=./terraform plan -out=plan.cache

.PHONY: terraform-apply
terraform-apply: $(CI_ENV_FILE) terraform/plan.cache $(TF_STATE_FILE) ensure-grafana-online ## terraform apply
	# terraform apply
	@set -a; source $<; set +a; \
	TF_VAR_aws_region=$${TF_AWS_REGION} TF_VAR_aws_access_key=$${TF_AWS_ACCESS_KEY_ID} TF_VAR_aws_secret_key=$${TF_AWS_SECRET_ACCESS_KEY} terraform -chdir=./terraform apply plan.cache

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
		status_code=$$(curl -k -o /dev/null -s -w "%{http_code}" $$url); \
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
