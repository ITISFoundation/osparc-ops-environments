# monitoring stack

![](https://cdn.rawgit.com/prometheus/prometheus/e761f0d/documentation/images/architecture.svg)


Monitoring using prometheus and graphana

    $ HOSTNAME=$(hostname) docker stack deploy -c docker-compose.yml ops-monitoring


- graphana: http://127.0.0.1:3000   [admin, foobar]
- prometheus: http://127.0.0.1:9090


## References

- [prometheus]
- https://github.com/vegasbrianc/prometheus



[PromQL]:https://prometheus.io/docs/prometheus/latest/querying/basics
[prometheus]:https://prometheus.io/docs
