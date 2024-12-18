
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
}
