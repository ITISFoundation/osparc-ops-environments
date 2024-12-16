terraform {
  required_version = "~> 1.5.1"
  backend "local" {
    path = "terraform.tfstate" # Specify the path for the state file, can be a different path if needed
  }
  required_providers {
    grafana = {
      source  = "grafana/grafana"
      version = "~> 3.13"
    }
    random = {
      source  = "hashicorp/random"
      version = "~> 3.1"
    }
  }
}

provider "grafana" {
  url  = var.grafana_url
  auth = var.grafana_auth
}
