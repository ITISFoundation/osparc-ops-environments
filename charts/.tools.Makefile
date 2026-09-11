#
# Variables
#

# Helmfile version is dictated by helm version installed in the cluster.
# Kubepsray dictates the helm version to be installed in the cluster.
# Based on helm version choose the highest compatible helmfile version.
# (helmfile defines minimum required helm version)
# NOTE: keep in sync with github workflows and version in running clusters
HELMFILE_EXPECTED_VERSION := 1.1.0

# NOTE: keep in sync with version used in github workflows (actions)
TRIVY_EXPECTED_VERSION := 0.72.0

#
# Helpers
#

# $(call verify_tool_installation,tool,expected_version)
define verify_tool_installation
	@if ! command -v $(1) >/dev/null 2>&1; then \
		echo "'$(1)' is not installed. Install version $(2) to continue."; \
		echo "Try 'make install-$(1)'"; \
		exit 1; \
	fi
	@if ! $(1) --version | grep -q "$(2)"; then \
		echo "WARNING: installed $(1) version does not match" > /dev/stderr; \
		echo "Expected $(1) version:'$(2)'. Please, update!" > /dev/stderr; \
		echo "Try 'make install-$(1)'" > /dev/stderr; \
		sleep 3s; \
	fi
endef

#
# Verifying tools installation
#

.PHONY: .verify-helmfile-installation
.verify-helmfile-installation: guard-HELMFILE_EXPECTED_VERSION
	$(call verify_tool_installation,helmfile,$(HELMFILE_EXPECTED_VERSION))

.PHONY: .verify-trivy-installation
.verify-trivy-installation: guard-TRIVY_EXPECTED_VERSION
	$(call verify_tool_installation,trivy,$(TRIVY_EXPECTED_VERSION))


#
# Installing tools
#

.PHONY: install-helmfile
install-helmfile: guard-HELMFILE_EXPECTED_VERSION
	# installing helmfile...
	@os="$$(uname -s | tr '[:upper:]' '[:lower:]')"; \
	arch="$$(uname -m)"; \
	case "$$arch" in aarch64) arch=arm64;; x86_64) arch=amd64;; esac; \
	url="https://github.com/helmfile/helmfile/releases/download/v$(HELMFILE_EXPECTED_VERSION)/helmfile_$(HELMFILE_EXPECTED_VERSION)_$${os}_$${arch}.tar.gz"; \
	curl --silent --show-error --location "$$url" | tar xz -C /tmp helmfile
	sudo install /tmp/helmfile /usr/local/bin/helmfile
	@rm /tmp/helmfile
	# installing helmfile plugins...
	@helmfile init --force --quiet
	@helmfile version

.PHONY: install-trivy
install-trivy: guard-TRIVY_EXPECTED_VERSION
	# installing trivy ...
	@curl --silent --show-error --location \
		https://raw.githubusercontent.com/aquasecurity/trivy/main/contrib/install.sh \
		| sudo sh -s -- -b /usr/local/bin v$(TRIVY_EXPECTED_VERSION)
	@trivy --version
