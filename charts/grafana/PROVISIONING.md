# Grafana provisioning via sidecar

The Grafana sidecar watches Kubernetes resources (across namespaces — see `searchNamespace` in values) and provisions them automatically.

## How to add a datasource

### Rules

1. Explicitly define datasource `uid` and `type`.
2. Store uid & type in chart values so dashboards can reference them.
3. Set `isDefault: false` — dashboards must reference the datasource explicitly.

### Example (Helm template)

```yaml
apiVersion: v1
kind: Secret
metadata:
  name: my-grafana-datasource
  labels:
    grafana_datasource: 'true_string'  # without this label grafana won't import this datasource
stringData:
  datasource.yaml: |-
    apiVersion: 1
    datasources:
      - name: VictoriaMetrics
        type: {{ .Values.grafanaMetricsDatasourceType }}
        uid: {{ .Values.metricsDatasourceUid }}
        access: proxy
        url: http://...
        isDefault: false
        editable: true
```

Source: https://github.com/grafana/helm-charts/tree/main/charts/grafana#sidecar-for-datasources

## How to add a dashboard

### Get dashboard json file

1. Make dashboard in grafana UI
2. Export dashboard as json file
3. Replace hardcoded datasource uid/type with `__DS_UID__` / `__DS_TYPE__`
4. Add config map with dashboard json and special label
5. When rendering dashboard json datasource replace uid/type variables with real values

NOTE: if you have multiple datasources, just use multiple variables. It is fine as long as you replace them at helm render time

### Example (Helm template)

```yaml
{{- $dashboardContent := .Files.Get "files/dashboards/dashboard.json"
  | replace "__DS_UID__" .Values.datasourceUid
  | replace "__DS_TYPE__" .Values.datasourceType -}}

apiVersion: v1
kind: ConfigMap
metadata:
  name: autoscaling-overview
  labels:
    grafana_dashboard: "true_string" # important: without this label grafana would ignore the config map
  annotations:
    dashboard_folder: "Simcore" # important: nested folders are not supported https://github.com/grafana/grafana/pull/119852
data:
  dashboard.json: | {{ $dashboardContent | nindent 4 }}
```

See real implementation in `charts/victoria-metrics-k8s-stack`

Source: https://github.com/grafana/helm-charts/tree/main/charts/grafana#sidecar-for-dashboards

## Troubleshooting

* Check sidecar settings in values file and see comments to get clues for behaviour in different scenarios
* Make sure the corresponding ConfigMap / Secret exists in the expected namespace.
* Check sidecar logs: (see logs of sidecars running inside grafana pod)
