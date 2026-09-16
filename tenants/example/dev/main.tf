terraform {
  required_version = ">= 1.6.0"

  required_providers {
    kubernetes = {
      source  = "hashicorp/kubernetes"
      version = "~> 2.0"
    }
  }

  # Configure a dedicated remote backend for this tenant/environment before use.
  backend "http" {}
}

provider "kubernetes" {
  host                   = var.openshift_api_url
  token                  = var.openshift_token
  cluster_ca_certificate = var.openshift_ca_certificate
}

locals {
  image = "${var.container_registry}/${var.image_repository}:${var.image_tag}"
}

module "pod" {
  source = "../../../modules/openshift-pod"

  name                 = var.pod_name
  namespace            = var.namespace
  image                = local.image
  container_name       = var.container_name
  service_account_name = var.service_account_name
  labels               = var.labels
  annotations          = var.annotations
  cpu_request          = var.cpu_request
  memory_request       = var.memory_request
  cpu_limit            = var.cpu_limit
  memory_limit         = var.memory_limit
}
