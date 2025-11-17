# to be executed on kubernetes control nodes
REPO_BASE_DIR := $(shell git rev-parse --show-toplevel)

include ${REPO_BASE_DIR}/scripts/common.Makefile

enable-flow-logs:
	@$(call confirm_action,Are you using calico 3.30+?,yes)
	kubectl apply -f flowlogs.yaml
	kubectl port-forward -n calico-system service/whisker 8081:8081
