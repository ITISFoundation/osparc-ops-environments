{{/*
Service name of the victoria-logs-single server, matching what the subchart renders.
*/}}
{{- define "victoria-logs-single.serverServiceName" -}}
{{- $vm := index .Values "victoria-logs-single" -}}
{{- $vm.server.fullnameOverride -}}
{{- end -}}
