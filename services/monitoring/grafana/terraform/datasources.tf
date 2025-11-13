
resource "grafana_data_source" "prometheusfederation" {
  type               = "prometheus"
  name               = "prometheus-federation"
  url                = var.PROMETHEUS_FEDERATION_URL
  basic_auth_enabled = false
  is_default         = true
}

resource "grafana_data_source" "prometheuscatchall" {
  type               = "prometheus"
  name               = "prometheus-catchall"
  url                = var.PROMETHEUS_CATCHALL_URL
  basic_auth_enabled = false
  is_default         = false
  uid                = "RmZEr52nz"

  json_data_encoded = jsonencode({
    exemplarTraceIdDestinations = [
      {
        datasourceUid = "tempo"
        name          = "TraceID"
      }
    ]
  })

}

resource "grafana_data_source" "tempo" {
  type               = "tempo"
  name               = "tempo"
  url                = var.TEMPO_URL
  basic_auth_enabled = false
  is_default         = false
  uid                = "delr011tpeupsc"

  json_data_encoded = jsonencode({
    tracesToLogsV2 = {
      datasourceUid      = grafana_data_source.loki.uid
      spanStartTimeShift = "-5m"
      spanEndTimeShift   = "5m"
      filterByTraceID    = false
      filterBySpanID     = false
      customQuery        = true
      query              = "{source=\"vector\"} | json | log_trace_id = `$${__span.traceId}` | log_span_id = `$${__span.spanId}` | line_format `{{.log_msg}}`"
    }
  })
}

resource "grafana_data_source" "loki" {
  type               = "loki"
  name               = "loki"
  url                = "http://loki:3100"
  basic_auth_enabled = false
  is_default         = false

  json_data_encoded = jsonencode({
    derivedFields = [
      {
        datasourceUid = "tempo"
        matcherType   = "label"
        matcherRegex  = "log_trace_id"
        name          = "TraceID"
        url           = "$${__value.raw}"
      }
    ]
  })
}
resource "grafana_data_source" "cloudwatch" {
  # This resource is only created if the AWS Deployments
  count = var.IS_AWS_DEPLOYMENT ? 1 : 0

  type = "cloudwatch"
  name = "cloudwatch"
  uid  = "fem2inr5v64n4c"

  json_data_encoded = jsonencode({
    defaultRegion = var.AWS_DEFAULT_REGION
    authType      = "keys"
  })

  secure_json_data_encoded = jsonencode({
    accessKey = var.GRAFANA_CLOUDWATCH_DATASOURCE_USER_ACCESS_KEY
    secretKey = var.GRAFANA_CLOUDWATCH_DATASOURCE_USER_SECRET_KEY
  })
}
