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
variable "image" { type = string }
variable "container_name" { type = string, default = "application" }
variable "service_account_name" { type = string, default = "default" }
variable "labels" { type = map(string), default = {} }
variable "annotations" { type = map(string), default = {} }
variable "cpu_request" { type = string, default = "100m" }
variable "memory_request" { type = string, default = "128Mi" }
variable "cpu_limit" { type = string, default = "500m" }
variable "memory_limit" { type = string, default = "512Mi" }
