SHELL := /bin/bash

current_dir := $(shell pwd)
SWARM_STACK_NAME  := $(notdir $(shell pwd))

.PHONY: help
help: ## help on rule's targets
	@awk --posix 'BEGIN {FS = ":.*?## "} /^[[:alpha:][:space:]_-]+:.*?## / {printf "\033[36m%-20s\033[0m %s\n", $$1, $$2}' $(MAKEFILE_LIST)


#
# CONFIG from templates & osparc-config secrets
#


.PHONY: .env .api_env  appmotion_payments_gateway_env

.env: .secrets  template.env ## captures necessary vars from `.secrets` into `.env` (TIP: `ln -s path/to/osparc-config/deployments/foo.com/repo.config .secrets`)
	@set -o allexport; source $<  ; set +o allexport; envsubst < $(word 2,$^) > $@


.api_env: .env template.api_env
	@set -o allexport; source $<  ; set +o allexport; envsubst < $(word 2,$^) > $@


appmotion_payments_gateway_env: .api_env  ## re-creates docker config
	@docker config inspect $@ > /dev/null 2>&1 && docker config rm $@ || true
	@docker config create $@ $<


## NOTE: docker compose --env-file=$< config --output $@   DOES NOT WORK!!
.stack/docker-compose.yml: .env docker-compose.yml ## creates compose specs for swarm
	@mkdir -p .stack	
	@set -o allexport; source $<; set +o allexport; \
	docker stack config --compose-file $(word 2,$^) >$@



#
# docker SWARM
#


.PHONY: stack
stack: .stack/docker-compose.yml appmotion_payments_gateway_env ## deploys stack in current swarm (swarm must be initiated)
	docker stack deploy --with-registry-auth --prune --compose-file $< ${SWARM_STACK_NAME}


.PHONY: stack-rm
stack-rm: ## removes stack from current swarm
	docker stack rm ${SWARM_STACK_NAME}


.PHONY: stack-ls
stack-ls: ## lists stack in current swarm
	docker stack list
