.DEFAULT_GOAL := help



# Internal VARIABLES ------------------------------------------------
# STACK_NAME defaults to name of the current directory. Should not to be changed if you follow GitOps operating procedures.
STACK_NAME = $(notdir $(shell pwd))
SWARM_HOSTS = $(shell docker node ls --format={{.Hostname}} 2>/dev/null)
TEMP_COMPOSE=.stack.${STACK_NAME}.yaml
REPO_BASE_DIR := $(shell git rev-parse --show-toplevel)

# TARGETS --------------------------------------------------
include ${REPO_BASE_DIR}/scripts/common.Makefile

.PHONY: up-master ## Deploys jaeger stack for Dalco Cluster
up-master: .init .env ${TEMP_COMPOSE}-master
	@docker stack deploy --with-registry-auth --prune --compose-file ${TEMP_COMPOSE}-master ${STACK_NAME}

.PHONY: up-devel ## Deploys jaeger stack for Dalco Cluster
up-devel: .init .env ${TEMP_COMPOSE}-devel
	@docker stack deploy --with-registry-auth --prune --compose-file ${TEMP_COMPOSE}-devel ${STACK_NAME}



# Helpers -------------------------------------------------

.PHONY: ${TEMP_COMPOSE}
${TEMP_COMPOSE}: docker-compose.yml
	@${REPO_BASE_DIR}/scripts/docker-compose-config.bash $< > $@

.PHONY: ${TEMP_COMPOSE}-letsencrypt-http
${TEMP_COMPOSE}-letsencrypt-http: docker-compose.yml docker-compose.letsencrypt.http.yml
	@${REPO_BASE_DIR}/scripts/docker-compose-config.bash $< docker-compose.letsencrypt.http.yml  > $@

.PHONY: ${TEMP_COMPOSE}-letsencrypt-dns
${TEMP_COMPOSE}-letsencrypt-dns: docker-compose.yml docker-compose.letsencrypt.dns.yml
	@${REPO_BASE_DIR}/scripts/docker-compose-config.bash $< docker-compose.letsencrypt.dns.yml  > $@

.PHONY: ${TEMP_COMPOSE}-master
${TEMP_COMPOSE}-master: docker-compose.yml docker-compose.letsencrypt.dns.yml docker-compose.master.yml
	@${REPO_BASE_DIR}/scripts/docker-compose-config.bash $< docker-compose.letsencrypt.dns.yml docker-compose.master.yml  > $@

.PHONY: ${TEMP_COMPOSE}-devel
${TEMP_COMPOSE}-devel: docker-compose.yml docker-compose.devel.yml
	@${REPO_BASE_DIR}/scripts/docker-compose-config.bash docker-compose.devel.yml  > $@
