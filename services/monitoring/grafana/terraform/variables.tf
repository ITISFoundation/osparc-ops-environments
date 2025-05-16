variable "GRAFANA_URL" {
  description = "grafana_url"
  sensitive   = false
}
variable "TEMPO_URL" {
  description = "tempo_url"
  sensitive   = false
}
variable "GRAFANA_AUTH" {
  description = "Username:Password"
  sensitive   = true
}
variable "PROMETHEUS_FEDERATION_URL" {
  description = "Prometheus Federation URL"
  sensitive   = false
}
variable "PROMETHEUS_CATCHALL_URL" {
  description = "Prometheus Catchall URL"
  sensitive   = false
}

variable "AWS_DEFAULT_REGION" {
  description = "AWS Default Region"
  sensitive   = false
}

variable "AWS_GRAFANA_CLOUDWATCH_DATASOURCE_USER_ACCESS_KEY" {
  description = "AWS Grafana Cloudwatch User Access Key"
  sensitive   = true
}

variable "AWS_GRAFANA_CLOUDWATCH_DATASOURCE_USER_SECRET_KEY" {
  description = "AWS Grafana Cloudwatch User Secret Key"
  sensitive   = true
}
