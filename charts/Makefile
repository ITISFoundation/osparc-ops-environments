REPO_BASE_DIR := $(shell git rev-parse --show-toplevel)

# TARGETS --------------------------------------------------
include ${REPO_BASE_DIR}/scripts/common.Makefile

up-local:

	@$(MAKE) -s up-local-post-install

.PHONY: configure-hosts
configure-hosts:
	@grep -q 'k8s.monitoring.osparc.local' /etc/hosts || echo '127.0.0.1 k8s.monitoring.osparc.local' | sudo tee -a /etc/hosts

up-local-post-install: configure-hosts
	@echo "Cluster has been deployed locally: http://osparc.local"
	@echo "    For secure connections self-signed certificates are used."
	@echo "    Install root-ca certificate in your system for smooth experience"
