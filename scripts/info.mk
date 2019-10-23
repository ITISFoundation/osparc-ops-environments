.PHONY: info info-debug info-swarm

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
