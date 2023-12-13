.DEFAULT_GOAL := help



# Internal VARIABLES ------------------------------------------------
# STACK_NAME defaults to name of the current directory. Should not to be changed if you follow GitOps operating procedures.
STACK_NAME = $(notdir $(shell pwd))
IS_PORTAINER_SERVICE_RUNNING = $(shell docker service ls | grep portainer_portainer | wc -l | grep 1)
TEMP_COMPOSE=.stack.${STACK_NAME}.yaml
REPO_BASE_DIR := $(shell git rev-parse --show-toplevel)

# Makefile including function used by every services
include ${REPO_BASE_DIR}/scripts/common.Makefile

.PHONY: up ## Deploys portainer stack
up: .init .env secrets ${TEMP_COMPOSE}
	@docker stack deploy --with-registry-auth --prune --compose-file ${TEMP_COMPOSE} ${STACK_NAME}

.PHONY: up-local ## Deploys portainer stack for local deployment
up-local: .init .env secrets ${TEMP_COMPOSE} ${TEMP_COMPOSE}-local
	@docker stack deploy --with-registry-auth --prune --compose-file ${TEMP_COMPOSE}-local ${STACK_NAME}

.PHONY: up-letsencrypt-http ## Deploys portainer stack using let's encrypt http challenge
up-letsencrypt-http: .init .env secrets ${TEMP_COMPOSE}-letsencrypt-http
	@docker stack deploy --with-registry-auth --prune --compose-file ${TEMP_COMPOSE}-letsencrypt-http ${STACK_NAME}

.PHONY: up-letsencrypt-dns ## Deploys portainer stack using let's encrypt dns challenge
up-letsencrypt-dns: .init .env secrets ${TEMP_COMPOSE}-letsencrypt-dns
	@docker stack deploy --with-registry-auth --prune --compose-file ${TEMP_COMPOSE}-letsencrypt-dns ${STACK_NAME}

.PHONY: up-dalco ## Deploys portainer stack for Dalco Cluster
up-dalco: .init .env secrets ${TEMP_COMPOSE}-dalco
	@docker stack deploy --with-registry-auth --prune --compose-file ${TEMP_COMPOSE}-dalco ${STACK_NAME}

.PHONY: up-aws ## Deploys portainer stack for AWS
up-aws: .init .env secrets ${TEMP_COMPOSE}-aws
	@docker stack deploy --with-registry-auth --prune --compose-file ${TEMP_COMPOSE}-aws ${STACK_NAME}

.PHONY: up-public ## Deploys portainer stack for public access Cluster
up-public: up-dalco

.PHONY: up-master ## Deploys portainer stack for master Cluster
up-master: .init .env secrets ${TEMP_COMPOSE}-master
	@docker stack deploy --with-registry-auth --prune --compose-file ${TEMP_COMPOSE}-master ${STACK_NAME}


.PHONY: configure-registry
configure-registry:  ## Add if necessary dockerhub registry configuration to portainer.
	@set -o allexport; \
	source $(REPO_CONFIG_LOCATION); \
	set +o allexport; \
	while [ "$$(curl -s -o /dev/null -I -w "%{http_code}" --max-time 10  -H "Accept: application/json" -H "Content-Type: application/json" -X GET https://"$$MONITORING_DOMAIN"/portainer/#/auth)" != 200 ]; do\
		echo "waiting for portainer to run...";\
		sleep 5s;\
	done;\
	echo "Updating docker-hub config";\
	authentificationToken=$$(curl -o /dev/null -X POST "https://"$$MONITORING_DOMAIN"/portainer/api/auth" -H  "Content-Type: application/json" -d "{  \"Username\": \"$${PORTAINER_ADMIN_LOGIN}\",  \"Password\": \"$${PORTAINER_ADMIN_PWD}\"}"); \
	authentificationToken=$$(echo "$$authentificationToken" | jq --raw-output '.jwt'); \
	update_hub=$$(curl -o /dev/null -X PUT "https://"$$MONITORING_DOMAIN"/portainer/api/dockerhub" -H  "accept: application/json" -H \
	"Authorization: Bearer $${authentificationToken}" -H  "Content-Type: application/json" \
	-d "{  \"Authentication\": true,  \"Username\": \"$$DOCKER_HUB_LOGIN\",  \"Password\": \"$$DOCKER_HUB_PASSWORD\"}"); \


# Helpers -------------------------------------------------

.PHONY: ${TEMP_COMPOSE}
${TEMP_COMPOSE}: docker-compose.yml .env
	@${REPO_BASE_DIR}/scripts/docker-compose-config.bash -e .env $< > $@

.PHONY: ${TEMP_COMPOSE}-letsencrypt-http
${TEMP_COMPOSE}-letsencrypt-http: docker-compose.yml docker-compose.letsencrypt.http.yml .env
	@${REPO_BASE_DIR}/scripts/docker-compose-config.bash -e .env $< docker-compose.letsencrypt.http.yml > $@

.PHONY: ${TEMP_COMPOSE}-letsencrypt-dns
${TEMP_COMPOSE}-letsencrypt-dns: docker-compose.yml docker-compose.letsencrypt.dns.yml .env
	@${REPO_BASE_DIR}/scripts/docker-compose-config.bash -e .env $< docker-compose.letsencrypt.dns.yml > $@

.PHONY: ${TEMP_COMPOSE}-dalco
${TEMP_COMPOSE}-dalco: docker-compose.yml docker-compose.dalco.yml .env
	@${REPO_BASE_DIR}/scripts/docker-compose-config.bash -e .env $< docker-compose.dalco.yml  > $@

.PHONY: ${TEMP_COMPOSE}-master
${TEMP_COMPOSE}-master: docker-compose.yml docker-compose.master.yml .env
	@${REPO_BASE_DIR}/scripts/docker-compose-config.bash -e .env $< docker-compose.master.yml  > $@

.PHONY: ${TEMP_COMPOSE}-local
${TEMP_COMPOSE}-local: docker-compose.yml docker-compose.local.yml .env
	@${REPO_BASE_DIR}/scripts/docker-compose-config.bash -e .env $< docker-compose.local.yml > $@

.PHONY: ${TEMP_COMPOSE}-aws
${TEMP_COMPOSE}-aws: docker-compose.yml docker-compose.aws.yml docker-compose.letsencrypt.dns.yml .env
	@${REPO_BASE_DIR}/scripts/docker-compose-config.bash -e .env $< docker-compose.aws.yml docker-compose.letsencrypt.dns.yml > $@

.PHONY: secrets
secrets: .env ## Construct secrets for portainer pwd, to change pwd it need to be done manually https://git.speag.com/oSparc/osparc-ops-deployment-configuration/-/wikis/Update-Portainer-Password
	@if [ -z $(IS_PORTAINER_SERVICE_RUNNING) ]; then\
		echo "Setting portainer_admin_password (can only set but not update password!)" \
		&& docker secret rm portainer_admin_password 2>/dev/null; \
		set -o allexport; source .env; set +o allexport; \
		echo -n "$${PORTAINER_ADMIN_PWD}" | docker secret create portainer_admin_password -  2>/dev/null; \
    fi
