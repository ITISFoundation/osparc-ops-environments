REPO_BASE_DIR := $(shell git rev-parse --show-toplevel)

include ${REPO_BASE_DIR}/scripts/common.Makefile
include $(REPO_CONFIG_LOCATION)

CONFIG_DIR := $(dir $(REPO_CONFIG_LOCATION))
CHART_DIRS := $(wildcard $(REPO_BASE_DIR)/charts/*/)

.PHONY: .check-helmfile-installed
.check-helmfile-installed:
	@if ! command -v helmfile >/dev/null 2>&1; then \
			echo "'helmfile' is not installed. Install it to continue ...";\
	fi

.PHONY: values.yaml
values.yaml:
	@echo "configuring $@ for charts..."
	@for dir in $(CHART_DIRS); do \
		if [ -f $$dir/values.yaml.j2 ]; then \
			$(MAKE) -s -C $$dir values.yaml; \
		fi; \
	done

.PHONY: values.local.yaml
values.local.yaml:
	@echo "configuring $@ for charts..."
	@for dir in $(CHART_DIRS); do \
		if [ -f $$dir/values.local.yaml.j2 ]; then \
			$(MAKE) -s -C $$dir values.local.yaml; \
		fi; \
	done

helmfile.yaml:
	cp $(CONFIG_DIR)/helmfile.yaml $(REPO_BASE_DIR)/charts/helmfile.yaml

.PHONY: .helmfile-apply
.helmfile-apply: .check-helmfile-installed helmfile.yaml
	helmfile -f $(REPO_BASE_DIR)/charts/helmfile.yaml apply

.PHONY: .helmfile-diff
.helmfile-diff: .check-helmfile-installed helmfile.yaml
	helmfile -f $(REPO_BASE_DIR)/charts/helmfile.yaml diff

.PHONY: .helmfile-delete
.helmfile-delete: .check-helmfile-installed helmfile.yaml
	helmfile -f $(REPO_BASE_DIR)/charts/helmfile.yaml delete

.PHONY: configure-local-hosts
configure-local-hosts:
	@echo "Addings osparc.local hosts to /etc/hosts ..."
	@grep -q '127.0.0.1 k8s.monitoring.osparc.local' /etc/hosts || echo '127.0.0.1 k8s.monitoring.osparc.local' | sudo tee -a /etc/hosts

.PHONY: apply-local
apply-local: values.local.yaml values.yaml .helmfile-apply configure-local-hosts
	@echo "Cluster has been deployed locally: http://$(MACHINE_FQDN)"
	@echo "    For secure connections self-signed certificates are used."
	@echo "    Install their root-ca certificate in your system for smooth experience."
	@echo "    For insecure connections make sure to disable automatic https redirects in your browser."

.PHONY: diff-local
diff-local: values.local.yaml values.yaml .helmfile-diff

.PHONY: delete-local
delete-local: values.local.yaml values.yaml .helmfile-delete

.PHONY: apply-master
apply-master: values.yaml .helmfile-apply

.PHONY: diff-master
diff-master: values.yaml .helmfile-diff

.PHONY: delete-master
delete-master: values.yaml .helmfile-delete
