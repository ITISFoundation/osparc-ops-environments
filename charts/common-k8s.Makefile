# Internal VARIABLES ------------------------------------------------
REPO_BASE_DIR := $(shell git rev-parse --show-toplevel)

values.local.yaml: values.local.yaml.j2
	set -a; source $(REPO_CONFIG_LOCATION); set +a; \
	envsubst < values.local.yaml.j2 > values.local.yaml

values.master.yaml: values.master.yaml.j2
	set -a; source $(REPO_CONFIG_LOCATION); set +a; \
	envsubst < values.master.yaml.j2 > values.master.yaml

values.yaml: values.yaml.j2
	set -a; source $(REPO_CONFIG_LOCATION); set +a; \
	envsubst < values.yaml.j2 > values.yaml
