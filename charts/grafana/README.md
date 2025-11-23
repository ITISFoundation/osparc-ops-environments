## How to add a dashboard

Create a Kubernetes config map with a special labels. It can be in any namespace (double check searchNamespace in dashboard sidecar container of grafana).

Important: do not harcode (used) datasource uid and type. Take these values from variables.

Example
```yaml
apiVersion: v1
kind: ConfigMap
metadata:
  name: sample-grafana-dashboard
  labels:
    grafana_dashboard: "1" # <--- special label. Take key and value from values
data:
  k8s-dashboard.json: |-
  [...]
```

Source: https://github.com/grafana/helm-charts/tree/main/charts/grafana#sidecar-for-dashboards

## How to add a datasource

Create a Kubernetes secret with a special labels. It can be in any namespace (double check searchNamespace in datasource sidecar container of grafana).

Important: explicitly define datasource uid & type and store these values in global values so that it can be referenced in other charts.

Example
```yaml
apiVersion: v1
kind: Secret
metadata:
  name: grafana-datasources
  labels:
    grafana_datasource: 'true'  # <--- special label. Take key and value from values
stringData:
  pg-db.yaml: |-
    apiVersion: 1
    datasources:
      - name: My pg db datasource
        type: postgres
        ...
```
kubectl -n grafana logs grafana-0 --container grafana-sc-dashboard
Source: https://github.com/grafana/helm-charts/tree/main/charts/grafana#sidecar-for-datasources

## Troubleshooting

#### Import dashboard / datasource does not work
* Make sure the corresponding `configmap` / `secret` exists
* Check logs of corresponding container in grafana pod
  - e.g. `kubectl -n grafana logs grafana-0 --container grafana-sc-dashboard`
