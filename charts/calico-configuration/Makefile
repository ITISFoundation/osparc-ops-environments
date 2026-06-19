REPO_BASE_DIR := $(shell git rev-parse --show-toplevel)

include ${REPO_BASE_DIR}/scripts/common.Makefile

enable-flow-logs: ## observe network traffic in kubernetes cluster
	@echo "It is only available for calico 3.30+"
	@echo "To find calico version being used, explore calico-node pod and see image version"
	@$(call confirm_action,Are you using calico 3.30+?,yes)

	# https://docs.tigera.io/calico/3.30/observability/enable-whisker
	kubectl apply -f flowlogs.yaml
	# View flow logs in browser: http://localhost:8081/
	# https://docs.tigera.io/calico/3.30/observability/view-flow-logs
	kubectl port-forward -n calico-system service/whisker 8081:8081
