# Grafana provisioning via sidecar

The Grafana sidecar watches Kubernetes resources (across namespaces - see `searchNamespace` in values) and provisions them automatically.

## How to add a datasource

1. Explicitly define datasource `uid` and `type`.
2. Store uid and type in chart values for datasource provisioning.
3. Set `isDefault: false` - dashboards should select their datasource explicitly.
4. In dashboard JSON, use datasource variables rather than binding to a chart-specific datasource UID.

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
        type: {{ .Values.metricsDatasourceType }}
        uid: {{ .Values.metricsDatasourceUid }}
        access: proxy
        url: http://...
        isDefault: false
        editable: true
```

Source: https://github.com/grafana/helm-charts/tree/main/charts/grafana#sidecar-for-datasources

## How to add a dashboard

1. Create a temporary dashboard in the Grafana UI.
2. Export it as JSON with **Model: V2** and enable **Share dashboard with another instance**.
3. Save the exported JSON under the owning chart's `files/dashboards/` directory.
4. Run the workspace prompt `.github/prompts/grafana-dashboard-convert-exported-json-file.prompt.md` on the exported JSON file. It validates the export, applies the owning chart's datasource placeholders and variables, and saves the converted dashboard in place.
5. Apply changes with helm (helmfile)
6. Delete the temporary dashboard.

### Example (Helm template)

```yaml
{{- $dashboardContent := .Files.Get "files/dashboards/dashboard.json"
  | replace "__DS_TYPE__" .Values.metricsDatasourceType -}}

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

Source: https://github.com/grafana/helm-charts/tree/main/charts/grafana#sidecar-for-dashboards

## How to update a dashboard

Provisioned dashboards are read-only in the UI, so edit a temporary copy instead of the original.

1. Create that copy by exporting the provisioned dashboard as JSON and importing it back as a new dashboard
2. Change the copy in the UI
3. Follow [How to add a dashboard](#how-to-add-a-dashboard) from step 2, overwriting the chart's existing file instead of adding a new one

**FAQ**

Why can't I edit an existing dashboard?
> UI updates are disabled (`allowUiUpdates: false` in the sidecar provider), so provisioned dashboards cannot be updated from the UI. Edit a copy instead (since it is not file-provisioned, it can be updated in UI)

Why can't I use the JSON from the save dialog of the original dashboard?
> That dialog has no **Share dashboard with another instance** toggle, so its JSON keeps instance-specific metadata and datasource references. See [grafana/grafana#134707](https://github.com/grafana/grafana/issues/134707).

## Troubleshooting

* Check sidecar settings in values file and see comments to get clues for behaviour in different scenarios
* Make sure the corresponding ConfigMap / Secret exists in the expected namespace.
* Check sidecar logs (see logs of sidecars running inside grafana pod)
