# monitoring stack for [osparc-simcore]

Creates a stack to monitor a [osparc-simcore] stack. Uses [prometheus](prometheus/README.md) and some exporters to scrap data from these services. Then it filtered and visualized in dashboards created with [graphana].

[Prometheus](prometheus/README.md) scraps data from the system or [osparc-simcore] services directy (for those instrumented with [servicelib/monitoring](https://github.com/ITISFoundation/osparc-simcore/blob/master/packages/service-library/src/servicelib/monitoring.py)) or via the following exporters:
  - [cdavisor](cadvisor/README.md): monitors containers in every node (one instance per node)
  - [node-exporter](node-exporter/README.md): monitors hardware (memory, filesystem, network) of every node. (one instance per node)
  - [postgres-exporter](postgres-exporter/README.md): scraps data from a *single* postgres db service defined in ``POSTGRES_EXPORTER_DATA_SOURCE_NAME``. Currently used to monitor the one-and-only database service in osparc but can be a limitation in the future.


## Usage

    $ make help
    $ make up
    $ make info
    $ make down

Available web front-ends when deployed in locahost:

- graphana: http://127.0.0.1:3000/dashboards
- prometheus: http://127.0.0.1:${MONITORING_PROMETHEUS_PORT}
- cAdvisor: http://127.0.0.1:8080/containers/
- Alertmanager: http://127.0.0.1:9093


## References

- https://github.com/vegasbrianc/prometheus





<!-- References below (keep alphabetical) -->
[grafana]:https://grafana.com
[osparc-simcore]:https://github.com/ITISFoundation/osparc-simcore
[PromQL]:https://prometheus.io/docs/prometheus/latest/querying/basics
