{{/*
Name of the secret containing container sensitive ENV
*/}}
{{- define "common-helpers.containerEnvSecretName" -}}
{{ printf "%s-%s" .Chart.Name "env-secret" | trunc 63 | trimSuffix "-" | quote }}
{{- end -}}

{{/*
Render container ENV. Depends on `common-helpers.containerEnvSecret`

Usage:
```
---
# values.yaml
env
  - name: RABBIT_HOST
    value: {{ requiredEnv "RABBIT_HOST"}}
  - name: RABBIT_PASSWORD
    value: {{ requiredEnv "RABBIT_PASSWORD"}}
    sensitive: true
---
# deployment.yaml
apiVersion: apps/v1
kind: Deployment
metadata:
  ...
  containers:
    - name: {{ .Chart.Name }}
        env:
        {{- include "common-helpers.containerEnv" . | nindent 12 }}
        ...
---
# secret.yaml
{{- include "common-helpers.containerEnvSecret" . | nindent 0 }}
```
*/}}
{{- define "common-helpers.containerEnv" -}}
{{- range .Values.env }}
- name: {{ .name }}
  {{- if .sensitive }}
  valueFrom:
    secretKeyRef:
      name: {{ include "common-helpers.containerEnvSecretName" $ }}
      key: {{ .name }}
  {{- else }}
  {{- if ne .value nil }}
  value: {{ .value | quote }}
  {{- else}}
  value: ""
  {{- end }}
  {{- end }}
{{- end }}
{{- end }}

{{/*

Usage:
{{- include "common-helpers.containerEnvSecret" . | nindent 0 }}

*/}}

{{- define "common-helpers.containerEnvSecret" -}}
apiVersion: v1
kind: Secret
metadata:
  name: {{ include "common-helpers.containerEnvSecretName" . }}
type: Opaque
data:
{{- range .Values.env }}
  {{- if .sensitive }}
  {{ .name }}: {{ .value | b64enc }}
  {{- end }}
{{- end }}
{{- end -}}
