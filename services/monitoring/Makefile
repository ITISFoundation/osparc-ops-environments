.DEFAULT_GOAL := help


# STACK_NAME defaults to name of the current directory. Should not to be changed if you follow GitOps operating procedures.
STACK_NAME = $(notdir $(CURDIR))
TEMP_COMPOSE=.stack.${STACK_NAME}.yaml
REPO_BASE_DIR := $(shell git rev-parse --show-toplevel)

# TARGETS --------------------------------------------------
include ${REPO_BASE_DIR}/scripts/common.Makefile

.PHONY: up
up: .init .env config.prometheus ${TEMP_COMPOSE} ## Deploys or updates current stack "$(STACK_NAME)". If MONITORED_NETWORK is not specified, it will create an attachable network
	@docker stack deploy --with-registry-auth --prune --compose-file ${TEMP_COMPOSE} $(STACK_NAME)
	$(MAKE) grafana-import

.PHONY: up-local
up-local: .init .env config.prometheus.simcore ${TEMP_COMPOSE}-local ## Deploys or updates current stack "$(STACK_NAME)". If MONITORED_NETWORK is not specified, it will create an attachable network
	@docker stack deploy --with-registry-auth --prune --compose-file ${TEMP_COMPOSE}-local $(STACK_NAME)
	$(MAKE) grafana-import

.PHONY: up-letsencrypt-http
up-letsencrypt-http: .init .env config.monitoring  config.prometheus ${TEMP_COMPOSE}-letsencrypt-http   ## Deploys or updates current stack "$(STACK_NAME)" using let's encrypt http challenge
	@docker stack deploy --with-registry-auth --prune --compose-file ${TEMP_COMPOSE}-letsencrypt-http ${STACK_NAME}
	$(MAKE) grafana-import

.PHONY: up-letsencrypt-dns
up-letsencrypt-dns: .init .env config.monitoring config.prometheus  ${TEMP_COMPOSE}-letsencrypt-dns   ## Deploys or updates current stack "$(STACK_NAME)" using let's encrypt dns challenge
	@docker stack deploy --with-registry-auth --prune --compose-file ${TEMP_COMPOSE}-letsencrypt-dns ${STACK_NAME}
	$(MAKE) grafana-import

.PHONY: up-dalco
up-dalco: .init .env  config.monitoring config.prometheus.ceph.simcore ${TEMP_COMPOSE}-dalco ## Deploys monitoring stack for Dalco Cluster
	@docker stack deploy --with-registry-auth --prune --compose-file ${TEMP_COMPOSE}-dalco ${STACK_NAME}
	$(MAKE) grafana-import

.PHONY: up-public
up-public: .init .env  config.monitoring config.prometheus ${TEMP_COMPOSE}-public ## Deploys monitoring stack for Public Cluster
	@docker stack deploy --with-registry-auth --prune --compose-file ${TEMP_COMPOSE}-public ${STACK_NAME}
	$(MAKE) grafana-import

.PHONY: up-aws
up-aws: .init .env config.monitoring config.prometheus.simcore.aws ${TEMP_COMPOSE}-aws   ## Deploys or updates current stack "$(STACK_NAME)" in AWS
	@docker stack deploy --with-registry-auth --prune --compose-file ${TEMP_COMPOSE}-aws ${STACK_NAME}
	$(MAKE) grafana-import

.PHONY: up-master
up-master: .init .env config.monitoring  config.prometheus.ceph.simcore ${TEMP_COMPOSE}-master ## Deploys monitoring stack for Master Cluster
	@docker stack deploy --with-registry-auth --prune --compose-file ${TEMP_COMPOSE}-master ${STACK_NAME}
	$(MAKE) grafana-import

${TEMP_COMPOSE}: docker-compose.yml config.monitoring .env pgsql_query_exporter_config.yaml smokeping_prober_config.yaml
	@${REPO_BASE_DIR}/scripts/docker-stack-config.bash -e .env $< > $@

${TEMP_COMPOSE}-letsencrypt-http: docker-compose.yml docker-compose.letsencrypt.http.yml config.monitoring .env pgsql_query_exporter_config.yaml smokeping_prober_config.yaml
	@${REPO_BASE_DIR}/scripts/docker-stack-config.bash -e .env $< docker-compose.letsencrypt.http.yml > $@

${TEMP_COMPOSE}-letsencrypt-dns: docker-compose.yml docker-compose.letsencrypt.dns.yml config.monitoring .env pgsql_query_exporter_config.yaml smokeping_prober_config.yaml
	@${REPO_BASE_DIR}/scripts/docker-stack-config.bash -e .env $< docker-compose.letsencrypt.dns.yml > $@

${TEMP_COMPOSE}-dalco: docker-compose.yml docker-compose.dalco.yml config.monitoring .env pgsql_query_exporter_config.yaml smokeping_prober_config.yaml
	@${REPO_BASE_DIR}/scripts/docker-stack-config.bash -e .env $< docker-compose.dalco.yml > $@

${TEMP_COMPOSE}-public: docker-compose.yml docker-compose.public.yml config.monitoring .env pgsql_query_exporter_config.yaml smokeping_prober_config.yaml
	@${REPO_BASE_DIR}/scripts/docker-stack-config.bash -e .env $< docker-compose.public.yml > $@

${TEMP_COMPOSE}-aws:  docker-compose.yml docker-compose.aws.yml config.monitoring .env pgsql_query_exporter_config.yaml smokeping_prober_config.yaml
	@${REPO_BASE_DIR}/scripts/docker-stack-config.bash -e .env $< docker-compose.aws.yml > $@

${TEMP_COMPOSE}-master: docker-compose.yml docker-compose.master.yml config.monitoring .env pgsql_query_exporter_config.yaml smokeping_prober_config.yaml
	@${REPO_BASE_DIR}/scripts/docker-stack-config.bash -e .env $< docker-compose.master.yml > $@

${TEMP_COMPOSE}-local: docker-compose.yml docker-compose.letsencrypt.dns.yml config.monitoring .env pgsql_query_exporter_config.yaml smokeping_prober_config.yaml
	@${REPO_BASE_DIR}/scripts/docker-stack-config.bash -e .env $< docker-compose.letsencrypt.dns.yml > $@

docker-compose.yml: docker-compose.yml.j2 .env .venv pgsql_query_exporter_config.yaml
	$(call jinja,$<,.env,$@)

.PHONY: update.grafana.pwd
update.grafana.pwd: .env ## Change grafana pwd
	@set -o allexport; \
	source $(REPO_CONFIG_LOCATION); \
	set +o allexport; \
	grafanacontainerid=$$(docker ps | grep grafana | awk '{print $$1;}');\
	docker exec -ti $$grafanacontainerid grafana-cli admin reset-admin-password $$TRAEFIK_PASSWORD


.PHONY: grafana-export
grafana-export: .venv## Export the remote grafana dashboards and datasources TO YOUR LOCAL MACHINE
	@cd grafana/scripts;\
	source ${REPO_BASE_DIR}/.venv/bin/activate;\
	pip install -r requirements.txt > /dev/null 2>&1;\
	python3 export.py;

.PHONY: grafana-import
grafana-import: grafana/assets ## Imports AND OVERWRITES the remote grafana dashboards and datasources FROM YOUR LOCAL MACHINE
	@pushd ${REPO_BASE_DIR}/services/monitoring/grafana && \
	$(MAKE) terraform-plan && \
	$(MAKE) terraform-apply; \
	popd > /dev/null


.PHONY: config.grafana.dashboards
config.grafana.dashboards: grafana/templates-provisioning/dashboards/simcore/Metrics-dashboard.json.j2 .venv #Configure dashboards for aws or dalco clusters
	$(call jinja, $<, .env, grafana/provisioning/dashboards/simcore/Metrics-dashboard.json)

.PHONY: config.monitoring
config.monitoring: grafana/template-config.monitoring ${REPO_CONFIG_LOCATION}
	@set -o allexport; \
	source $(REPO_CONFIG_LOCATION); \
	set +o allexport; \
	envsubst < $< > grafana/$@

.PHONY: config.prometheus.simcore
config.prometheus.simcore: ${REPO_CONFIG_LOCATION} .venv
	@set -o allexport; \
	source $<; \
	set +o allexport; \
	cat prometheus/prometheus-base.yml | $(_yq) '. *+ load("prometheus/prometheus-simcore.yml")' > prometheus/prometheus.yml; \
	envsubst < prometheus/prometheus.yml > prometheus/prometheus.temp.yml; \
	mv prometheus/prometheus.temp.yml prometheus/prometheus.yml

.PHONY: config.prometheus.simcore.aws
config.prometheus.simcore.aws: ${REPO_CONFIG_LOCATION} .venv
	@set -o allexport; \
	source $<; \
	set +o allexport; \
	cat prometheus/prometheus-base.yml | $(_yq) '. *+ load("prometheus/prometheus-simcore.yml")' | $(_yq) '. *+ load("prometheus/prometheus-aws.yml")' > prometheus/prometheus.yml; \
	envsubst < prometheus/prometheus.yml > prometheus/prometheus.temp.yml; \
	mv prometheus/prometheus.temp.yml prometheus/prometheus.yml

.PHONY: config.prometheus.ceph.simcore
config.prometheus.ceph.simcore: ${REPO_CONFIG_LOCATION} .venv
	@set -o allexport; \
	source $<; \
	set +o allexport; \
	$(call jinja, prometheus/prometheus-ceph.yml.j2, .env, prometheus/prometheus-ceph.yml); \
	cat prometheus/prometheus-base.yml | $(_yq) '. *+ load("prometheus/prometheus-simcore.yml")' | cat | \
	$(_yq) '. *+ load("prometheus/prometheus-ceph.yml")' > prometheus/prometheus.yml; \
	envsubst < prometheus/prometheus.yml > prometheus/prometheus.temp.yml; \
	mv prometheus/prometheus.temp.yml prometheus/prometheus.yml

.PHONY: config.prometheus
config.prometheus: ${REPO_CONFIG_LOCATION} .venv
	@set -o allexport; \
	source $<; \
	set +o allexport; \
	envsubst < prometheus/prometheus-base.yml > prometheus/prometheus.temp.yml; \
	mv prometheus/prometheus.temp.yml prometheus/prometheus.yml

pgsql_query_exporter_config.yaml: pgsql_query_exporter_config.yaml.j2 ${REPO_CONFIG_LOCATION} .env .venv
	$(call jinja, $<, .env, $@);

smokeping_prober_config.yaml: smokeping_prober_config.yaml.j2 ${REPO_CONFIG_LOCATION} .env .venv
	$(call jinja, $<, .env, $@);

.PHONY: grafana/assets
grafana/assets: ${REPO_CONFIG_LOCATION}
	@if [ ! -d "$(shell dirname ${REPO_CONFIG_LOCATION})/assets/grafana" ]; then \
		echo "Error: folder does not exist $$GRAFANA_ASSETS_DIR" >&2; \
		exit 1; \
	fi; \
	if [ ! -d "$(shell dirname ${REPO_CONFIG_LOCATION})/../shared/assets/grafana" ]; then \
		echo "Error: folder does not exist $$GRAFANA_COMMON_ASSETS_DIR" >&2; \
		exit 1; \
	fi; \
	rm -rf $(REPO_BASE_DIR)/services/monitoring/grafana/assets || true; \
	mkdir -p $(REPO_BASE_DIR)/services/monitoring/grafana/assets; \
	cp -r $(shell dirname ${REPO_CONFIG_LOCATION})/assets/grafana/* $(REPO_BASE_DIR)/services/monitoring/grafana/assets; \
	cp -r $(shell dirname ${REPO_CONFIG_LOCATION})/../shared/assets/grafana $(REPO_BASE_DIR)/services/monitoring/grafana/assets/shared; \
