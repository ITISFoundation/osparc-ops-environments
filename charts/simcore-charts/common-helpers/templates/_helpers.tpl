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

{{/*

Usage:
{{- include "common-helpers.defaultPodSecurityContext" . | nindent 0 }}

Defines a common pod security context to ensure minimal privileges for containers.

Values inspired from https://medium.com/dynatrace-engineering/kubernetes-security-part-3-security-context-7d44862c4cfa
*/}}
{{- define "common-helpers.defaultPodSecurityContext" -}}
runAsNonRoot: true
seccompProfile:
  type: RuntimeDefault
{{- end -}}

{{/*

Usage:
{{- include "common-helpers.defaultContainerSecurityContext" . | nindent 0 }}

Defines a common container security context to ensure minimal privileges for containers.

Values inspired from https://medium.com/dynatrace-engineering/kubernetes-security-part-3-security-context-7d44862c4cfa
*/}}
{{- define "common-helpers.defaultContainerSecurityContext" -}}
privileged: false
readOnlyRootFilesystem: true
allowPrivilegeEscalation: false
capabilities:
  drop:
    - ALL
{{- end -}}
