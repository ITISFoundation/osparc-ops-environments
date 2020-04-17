#
# Basic common targets and recipes
#

# TOOLS --------------------------------------

MAKE_C := $(MAKE) --no-print-directory --directory

# Operating system
ifeq ($(filter Windows_NT,$(OS)),)
IS_WSL  := $(if $(findstring Microsoft,$(shell uname -a)),WSL,)
IS_OSX  := $(filter Darwin,$(shell uname -a))
IS_LINUX:= $(if $(or $(IS_WSL),$(IS_OSX)),,$(filter Linux,$(shell uname -a)))
endif

.PHONY: help
help: ## help on rule's targets
ifeq ($(IS_WIN),)
	@awk --posix 'BEGIN {FS = ":.*?## "} /^[[:alpha:][:space:]_-]+:.*?## / {printf "\033[36m%-20s\033[0m %s\n", $$1, $$2}' $(MAKEFILE_LIST)
else
	@awk --posix 'BEGIN {FS = ":.*?## "} /^[[:alpha:][:space:]_-]+:.*?## / {printf "%-20s %s\n", $$1, $$2}' $(MAKEFILE_LIST)
endif


.PHONY: info info-images info-swarm  info-tools
info: ## displays setup information
	# setup info:
	@echo ' Detected OS          : $(IS_LINUX)$(IS_OSX)$(IS_WSL)$(IS_WIN)'
	@echo ' SWARM_STACK_NAME     : ${SWARM_STACK_NAME}'
	@echo ' DOCKER_REGISTRY      : $(DOCKER_REGISTRY)'
	@echo ' DOCKER_IMAGE_TAG     : ${DOCKER_IMAGE_TAG}'
	@echo ' BUILD_DATE           : ${BUILD_DATE}'
	@echo ' VCS_* '
	@echo '  - ULR                : ${VCS_URL}'
	@echo '  - REF                : ${VCS_REF}'
	# tools version
	@echo ' make   : $(shell make --version 2>&1 | head -n 1)'
	@echo ' jq     : $(shell jq --version)'
	@echo ' awk    : $(shell awk -W version 2>&1 | head -n 1)'
	@echo ' python : $(shell python3 --version)'



define show-meta
	$(foreach iid,$(shell docker images */$(1):* -q | sort | uniq),\
		docker image inspect $(iid) | jq '.[0] | .RepoTags, .ContainerConfig.Labels';)
endef

info-swarm: ## displays info about stacks and networks
ifneq ($(SWARM_HOSTS), )
	# Stacks in swarm
	@docker stack ls
	# Containers (tasks) running in '$(SWARM_STACK_NAME)' stack
	-@docker stack ps $(SWARM_HOSTS)
	# Services in '$(SWARM_STACK_NAME)' stack
	-@docker stack services $(SWARM_HOSTS)	
	# Networks
	@docker network ls
endif