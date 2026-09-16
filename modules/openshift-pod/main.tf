terraform {
  required_version = ">= 1.6.0"
  required_providers {
    kubernetes = {
      source  = "hashicorp/kubernetes"
      version = "~> 2.0"
    }
  }
}

resource "kubernetes_pod_v1" "this" {
  metadata {
    name      = var.name
    namespace = var.namespace
    labels    = var.labels
    annotations = var.annotations
  }

  spec {
    service_account_name = var.service_account_name
    restart_policy       = var.restart_policy

    container {
      name  = var.container_name
      image = var.image

      resources {
        requests = {
          cpu    = var.cpu_request
          memory = var.memory_request
        }
        limits = {
          cpu    = var.cpu_limit
          memory = var.memory_limit
        }
      }
    }
  }
}
