
## High Availability

Prometheus Server
* Issue asking how to configure it in `kube-prometheus-stack` https://github.com/prometheus-community/helm-charts/issues/6184
* Prometheus Operator Documentation https://github.com/prometheus-operator/prometheus-operator/blob/v0.85.0/Documentation/platform/high-availability.md#prometheus

Promethes Operator
* Not needed. See https://github.com/prometheus-operator/prometheus-operator/issues/2491

## FAQ

How to expose workload metrics
* Use ServiceMonitor, PodMonitor or Running exporters. See https://github.com/prometheus-community/helm-charts/blob/kube-prometheus-stack-77.12.0/charts/kube-prometheus-stack/README.md#prometheusioscrape
* Make sure network policy of prometheus and workload all all necessary ingress and egress
  - prometheus shall be able to egress for metrics and workload should allow ingress for metrics

Pod Monitor vs Service Monitor:
* https://github.com/prometheus-operator/prometheus-operator/issues/3119
