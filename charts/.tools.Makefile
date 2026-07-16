# Helmfile version is dictated by helm version installed in the cluster.
# Kubepsray dictates the helm version to be installed in the cluster.
# Based on helm version choose the highest compatible helmfile version.
# (helmfile defines minimum required helm version)
# NOTE: keep in sync with github workflows and version in running clusters
HELMFILE_EXPECTED_VERSION := 0.165.0

# NOTE: keep in sync with version used in github workflows (actions)
TRIVY_EXPECTED_VERSION := 0.71.2

# $(call verify_tool_installation,tool,expected_version)
define verify_tool_installation
	@if ! command -v $(1) >/dev/null 2>&1; then \
		echo "'$(1)' is not installed. Install version $(2) to continue ..."; \
		exit 1; \
	fi
	@if ! $(1) --version | grep -q "$(2)"; then \
		echo "WARNING: installed $(1) version does not match" > /dev/stderr; \
		echo "Expected $(1) version:'$(2)'. Please, update!" > /dev/stderr; \
		sleep 3s; \
	fi
endef

.PHONY: .verify-helmfile-installation
.verify-helmfile-installation:
	$(call verify_tool_installation,helmfile,$(HELMFILE_EXPECTED_VERSION))

.PHONY: .verify-trivy-installation
.verify-trivy-installation:
	$(call verify_tool_installation,trivy,$(TRIVY_EXPECTED_VERSION))
