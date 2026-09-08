REPO_BASE_DIR := $(shell git rev-parse --show-toplevel)

include ${REPO_BASE_DIR}/scripts/common.Makefile

#
# Vars
#

CHART_DIRS := $(wildcard $(REPO_BASE_DIR)/charts/*/) # intended: ignore hidden folders
CHART_NAMES := $(patsubst $(REPO_BASE_DIR)/charts/%/,%,$(CHART_DIRS))

#
# Targets
#

$(TRIVY_TEMPLATES_DIR):
	@echo "TRIVY_TEMPLATES_DIR=$(TRIVY_TEMPLATES_DIR) is missing"
	@echo "Generate it separately using ci deployment configuration"
	@exit 1

# This target is only relevant for CI deployment where we want to have all charts
# rendered to do static analysis
.PHONY: check-trivy-coverage
check-trivy-coverage: guard-TRIVY_TEMPLATES_DIR $(TRIVY_TEMPLATES_DIR) # ensure trivy scans all existing charts
	@return_code=0; \
	for chart_name in $(CHART_NAMES); do \
		if [ ! -d $(TRIVY_TEMPLATES_DIR)/$$chart_name ]; then \
			echo "Missing chart: $$chart_name"; \
			return_code=1; \
		fi; \
	done; \
	if [ $$return_code -eq 0 ]; then \
		echo "Trivy coverage check passed. All charts are scanned"; \
	fi; \
	exit $$return_code
