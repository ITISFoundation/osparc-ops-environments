
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
