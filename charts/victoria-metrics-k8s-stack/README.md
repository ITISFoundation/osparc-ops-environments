# Victoria metrics k8s stack

Official documentation https://docs.victoriametrics.com/helm/victoria-metrics-k8s-stack/

## Stack architecture (no HA)

See https://docs.victoriametrics.com/helm/victoria-metrics-k8s-stack/#overview

## VM Cluster (HA substitute of vm-single)

See Architecture Overview https://docs.victoriametrics.com/victoriametrics/cluster-victoriametrics/#architecture-overview

Note: HA setup requires at least 3 VMStorage while 2 VMStorage must be always up
* https://docs.victoriametrics.com/victoriametrics/cluster-victoriametrics/#replication-and-data-safety
* https://docs.victoriametrics.com/victoriametrics/cluster-victoriametrics/#high-availability
* https://docs.victoriametrics.com/victoriametrics/cluster-victoriametrics/#cluster-availability
