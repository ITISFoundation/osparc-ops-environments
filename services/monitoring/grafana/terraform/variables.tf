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

# to be used to create resource only for AWS / non AWS Deployments
# this is not syncronised / validated with dashboards imported from folders
variable "IS_AWS_DEPLOYMENT" {
  description = "Is AWS Deployment"
  type        = bool
  default     = false
}

variable "AWS_DEFAULT_REGION" {
  description = "AWS Region"
  sensitive   = false
}

variable "GRAFANA_CLOUDWATCH_DATASOURCE_USER_ACCESS_KEY" {
  description = "AWS Grafana Cloudwatch User Access Key"
  sensitive   = true
}

variable "GRAFANA_CLOUDWATCH_DATASOURCE_USER_SECRET_KEY" {
  description = "AWS Grafana Cloudwatch User Secret Key"
  sensitive   = true
}
