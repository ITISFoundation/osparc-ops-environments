#
# Basic common targets and recipes
#

.PHONY: help
help: ## This colourful help
	@awk 'BEGIN {FS = ":.*?## "} /^[a-zA-Z_-]+:.*?## / {printf "\033[36m%-20s\033[0m %s\n", $$1, $$2}' $(MAKEFILE_LIST)


.PHONY: info info-swarm

info: ## displays setup information
	# setup info:
	@echo ' makefile dir : $(CURDIR)'
	# tools version
	@echo ' make         : $(shell make --version 2>&1 | head -n 1)'
	@echo ' jq           : $(shell jq --version)'
	@echo ' awk          : $(shell awk -W version 2>&1 | head -n 1)'
	@echo ' python       : $(shell python3 --version)'

info-swarm: ## displays info about stacks and networks
ifneq ($(SWARM_HOSTS), )
	# Stacks in swarm
	@docker stack ls
	# Containers (tasks) running in '$(SWARM_HOSTS)' stack
	-@docker stack ps $(SWARM_HOSTS)
	# Services in '$(SWARM_HOSTS)' stack
	-@docker stack services $(SWARM_HOSTS)
	# Networks
	@docker network ls
endif


.PHONY: clean-unversioned
clean-unversioned:
	@git clean -ndxf -e .vscode/
	@echo -n "Are you sure? [y/N] " && read ans && [ $${ans:-N} = y ]
	@echo -n "$(shell whoami), are you REALLY sure? [y/N] " && read ans && [ $${ans:-N} = y ]
	# removing unversioned
	@git clean -dxf -e .vscode/



# $(call docker-compose-viz, stack-config)
#
#  Parses stack configuration and produces png diagram
#
# See https://github.com/pmsipilot/docker-compose-viz
#
define docker-compose-viz
	$(eval stack_config := $1)
	$(eval png_output := $(subst yml,png,$1))
	# Parsing $(stack_config) and producing $(png_output)
	docker run --rm -it \
		--name dcv-$1 \
		-v $(CURDIR):/input \
		pmsipilot/docker-compose-viz \
		render -m image $(stack_config) --force --output-file $(png_output)
endef
