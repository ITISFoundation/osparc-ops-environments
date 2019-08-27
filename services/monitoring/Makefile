
.PHONY: help
help: ##
	


.PHONY: up
up: ## Deploys
	docker swarm init
	HOSTNAME=$(hostname) docker stack deploy -c docker-compose.yml ops-monitoring


.PHONY: down
down: ## 

