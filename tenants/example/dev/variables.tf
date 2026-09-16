variable "openshift_api_url" {
  type = string
}

variable "openshift_token" {
  type      = string
  sensitive = true
}

variable "openshift_ca_certificate" {
  type      = string
  sensitive = true
}

variable "namespace" { type = string }
variable "pod_name" { type = string }

variable "container_registry" {
  description = "Container registry hostname and optional project path, without scheme or trailing slash. Example: harbor.example.internal/customer-a."
  type        = string

  validation {
    condition     = length(trimspace(var.container_registry)) > 0 && !startswith(var.container_registry, "http://") && !startswith(var.container_registry, "https://") && !endswith(var.container_registry, "/")
    error_message = "container_registry must be a registry hostname/path without http(s):// or trailing slash."
  }
}

variable "image_repository" {
  description = "Image repository relative to container_registry."
  type        = string
}

variable "image_tag" {
  description = "Immutable application image tag. The mutable latest tag is not allowed."
  type        = string

  validation {
    condition     = trimspace(var.image_tag) != "" && var.image_tag != "latest"
    error_message = "image_tag must be explicit and must not be latest."
  }
}

variable "container_name" { type = string, default = "application" }
variable "service_account_name" { type = string, default = "default" }
variable "labels" { type = map(string), default = {} }
variable "annotations" { type = map(string), default = {} }
variable "cpu_request" { type = string, default = "100m" }
variable "memory_request" { type = string, default = "128Mi" }
variable "cpu_limit" { type = string, default = "500m" }
variable "memory_limit" { type = string, default = "512Mi" }
