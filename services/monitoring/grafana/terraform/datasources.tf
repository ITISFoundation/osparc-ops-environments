
resource "grafana_data_source" "prometheusfederation" {
  type               = "prometheus"
  name               = "prometheus-federation"
  url                = var.prometheus_federation_url
  basic_auth_enabled = false
  is_default         = true
}

resource "grafana_data_source" "prometheuscatchall" {
  type               = "prometheus"
  name               = "prometheus-catchall"
  url                = var.prometheus_catchall_url
  basic_auth_enabled = false
  is_default         = false
  uid                = "RmZEr52nz"
}

resource "grafana_data_source" "tempo" {
  type               = "tempo"
  name               = "tempo"
  url                = var.tempo_url
  basic_auth_enabled = false
  is_default         = false
}
