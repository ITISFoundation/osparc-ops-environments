REPO_BASE_DIR := $(shell git rev-parse --show-toplevel)

include ${REPO_BASE_DIR}/scripts/common-services.Makefile
include ${REPO_BASE_DIR}/scripts/common.Makefile

#
# Operations
#

include ${REPO_BASE_DIR}/services/rabbit/.operations.Makefile

#
# Docker compose files
#

### Load Balancer
docker-compose.loadbalancer.yml: docker-compose.loadbalancer.yml.j2 \
					.env \
					configs/haproxy.cfg \
					venv \
					$(VENV_BIN)/j2
	@$(call jinja, $<, .env, $@)

.stack.loadbalancer.yml: docker-compose.loadbalancer.yml .env
	@${REPO_BASE_DIR}/scripts/docker-stack-config.bash -e .env $< > $@

### Node

.PRECIOUS: node0%.env
node0%.env: .env
	@envsubst < $< > $@; \
	echo NODE_INDEX=$* >> $@

.PRECIOUS: docker-compose.node0%.yml
docker-compose.node0%.yml: docker-compose.node0x.yml.j2 \
					node0%.env \
					configs/rabbitmq.conf \
					configs/erlang.cookie.secret \
					venv \
					$(VENV_BIN)/j2
	@$(call jinja, $<, node0$*.env, $@)

.PRECIOUS: .stack.node0%.yml
.stack.node0%.yml: docker-compose.node0%.yml node0%.env
	@${REPO_BASE_DIR}/scripts/docker-stack-config.bash -e node0$*.env $< > $@

#
# Config / Secret files
#

configs/erlang.cookie.secret: configs/erlang.cookie.secret.template .env
	@set -a; source .env; set +a; \
	envsubst < $< > $@

configs/rabbitmq.conf: configs/rabbitmq.conf.j2 .env venv
	# generate $@
	@$(call jinja, $<, .env, $@)

configs/haproxy.cfg: configs/haproxy.cfg.j2 .env venv
	# generate $@
	@$(call jinja, $<, .env, $@)
