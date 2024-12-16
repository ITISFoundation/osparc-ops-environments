variable "grafana_url" {
  description = "grafana_url"
  sensitive   = false
}
variable "grafana_auth" {
  description = "Username:Password"
  sensitive   = true
}
variable "prometheus_federation_url" {
  description = "Prometheus Federation URL"
  sensitive   = false
}
variable "prometheus_catchall_url" {
  description = "Prometheus Catchall URL"
  sensitive   = false
}
variable "tempo_url" {
  description = "Tempo URL"
  sensitive   = false
}
