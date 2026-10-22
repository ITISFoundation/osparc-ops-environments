REPO_BASE_DIR := $(shell git rev-parse --show-toplevel)
include $(REPO_BASE_DIR)/charts/local-k8s.Makefile

#
# Variables
#

USER_UID := $(shell id -u)
USER_GID := $(shell id -g)

#
# Artifacts
#

kind-kubeconfig.yaml: create-k8s-cluster
	kind get kubeconfig --name $(K8S_CLUSTER_NAME) --internal > $@
	chmod 600 $@

#
# Targets
#

opencode: kind-kubeconfig.yaml guard-optional-CMD
opencode: ## Run opencode in container
	USER_UID=$(USER_UID) USER_GID=$(USER_GID) \
	docker compose run --build --rm opencode $(CMD)
