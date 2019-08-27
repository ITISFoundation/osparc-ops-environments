# monitoring stack

Creates a stack for monitoring services based in [prometheus] and [graphana]

## Usage

    $ make help
    $ make up
    $ make info
    $ make down

Available web front-ends when deployed in locahost:

- graphana: http://127.0.0.1:3000/dashboards   [admin, foobar]
- prometheus: http://127.0.0.1:9090
- cAdvisor: http://127.0.0.1:8080/containers/
- Alertmanager: http://127.0.0.1:9093


## References

- [prometheus]
- https://github.com/vegasbrianc/prometheus

#### Makefile
- [Docker & Makefile | X-Ops — sharing infra-as-code parts](https://itnext.io/docker-makefile-x-ops-sharing-infra-as-code-parts-ea6fa0d22946)
- [Auto documented Makefile](https://marmelab.com/blog/2016/02/29/auto-documented-makefile.html)




<!-- References below (keep alphabetical) -->
[grafana]:https://grafana.com
[PromQL]:https://prometheus.io/docs/prometheus/latest/querying/basics
[prometheus]:https://prometheus.io/