REPO_BASE_DIR := $(shell git rev-parse --show-toplevel)
K8S_CLUSTER_NAME := osparc-cluster
# Determine this makefile's path.
# Be sure to place this BEFORE `include` directives, if any.
THIS_MAKEFILE := $(lastword $(MAKEFILE_LIST))

include ${REPO_BASE_DIR}/scripts/common.Makefile
include $(REPO_CONFIG_LOCATION)

create-cluster: ## Creates a local Kubernetes cluster
	@$(REPO_BASE_DIR)/scripts/create_local_k8s_cluster.bash $(K8S_CLUSTER_NAME)
	@$(MAKE) --no-print-directory --file $(THIS_MAKEFILE) configure-local-hosts
	@echo "";
	@echo "Cluster has been deployed locally: https://$(MACHINE_FQDN)";
	@echo "    For secure connections self-signed certificates are used.";
	@echo "";

delete-cluster: ## Deletes the local Kubernetes cluster
	@kind delete cluster --name $(K8S_CLUSTER_NAME)
	@echo "Local Kubernetes cluster $(K8S_CLUSTER_NAME) has been deleted."

.PHONY: configure-local-hosts
configure-local-hosts: $(REPO_CONFIG_LOCATION) ## Adds local hosts entries for the machine
	# "Updating /etc/hosts with k8s $(MACHINE_FQDN) hosts ..."
	@set -a; source $(REPO_CONFIG_LOCATION); set +a; \
	grep -q "127.0.0.1 $$K8S_MONITORING_FQDN" /etc/hosts || echo "127.0.0.1 $$K8S_MONITORING_FQDN" | sudo tee -a /etc/hosts
	@set -a; source $(REPO_CONFIG_LOCATION); set +a; \
	grep -q "127.0.0.1 $$K8S_PRIVATE_FQDN" /etc/hosts || echo "127.0.0.1 $$K8S_PRIVATE_FQDN" | sudo tee -a /etc/hosts
