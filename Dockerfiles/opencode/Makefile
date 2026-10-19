REPO_BASE_DIR := $(shell git rev-parse --show-toplevel)
include $(REPO_BASE_DIR)/charts/local-k8s.Makefile

#
# Artifacts
#

kind-kubeconfig.yaml: create-k8s-cluster
	kind get kubeconfig --name $(K8S_CLUSTER_NAME) --internal > $@
	chmod 600 $@

#
# Targets
#

opencode: guard-optional-CMD ## Run opencode in container
	docker compose run --build --rm opencode $(CMD)

opencode-with-kubernetes-cluster: kind-kubeconfig.yaml guard-optional-CMD
opencode-with-kubernetes-cluster: ## Run opencode in container connected with Kubernetes cluster
	docker compose -f docker-compose.yml -f docker-compose.kubernetes-cluster.yml \
		run --build --rm opencode $(CMD)
