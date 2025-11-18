REPO_BASE_DIR := $(shell git rev-parse --show-toplevel)

include ${REPO_BASE_DIR}/scripts/common.Makefile

enable-flow-logs: ## observe network traffic in kubernetes cluster
	@$(call confirm_action,Are you using calico 3.30+?,yes)
	# https://docs.tigera.io/calico/3.30/observability/enable-whisker
	kubectl apply -f flowlogs.yaml
	# https://docs.tigera.io/calico/3.30/observability/view-flow-logs
	kubectl port-forward -n calico-system service/whisker 8081:8081
