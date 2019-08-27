# monitoring stack

![](https://cdn.rawgit.com/prometheus/prometheus/e761f0d/documentation/images/architecture.svg)


Monitoring using prometheus and graphana

    $ make help
    $ make up
    $ make info
    $ make down


- graphana: http://127.0.0.1:3000/dashboards   [admin, foobar]
- prometheus: http://127.0.0.1:9090


## References

- [prometheus]
- https://github.com/vegasbrianc/prometheus

#### Makefile
- [Docker & Makefile | X-Ops — sharing infra-as-code parts](https://itnext.io/docker-makefile-x-ops-sharing-infra-as-code-parts-ea6fa0d22946)
- [Auto documented Makefile](https://marmelab.com/blog/2016/02/29/auto-documented-makefile.html)

[PromQL]:https://prometheus.io/docs/prometheus/latest/querying/basics
[prometheus]:https://prometheus.io/docs
