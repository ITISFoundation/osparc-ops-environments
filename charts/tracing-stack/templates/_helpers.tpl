{{/*
In-cluster host of the victoria-traces-single server: <fullname>.<ns>.svc.<dnsDomain>
*/}}
{{- define "tracing-stack.vtHost" -}}
{{- $vt := index .Values "victoria-traces-single" -}}
{{- $dnsDomain := index $vt "global" "cluster" "dnsDomain" -}}
{{- printf "%s.%s.svc.%s" $vt.server.fullnameOverride .Release.Namespace $dnsDomain -}}
{{- end -}}
