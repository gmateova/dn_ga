variable "name" {
  description = "Pod name."
  type        = string

  validation {
    condition     = length(trimspace(var.name)) > 0
    error_message = "name must not be empty."
  }
}

variable "namespace" {
  description = "Existing OpenShift project/namespace."
  type        = string
}

variable "container_name" {
  description = "Container name."
  type        = string
  default     = "application"
}

variable "image" {
  description = "Container image including registry and immutable tag/digest."
  type        = string
}

variable "labels" {
  type    = map(string)
  default = {}
}

variable "annotations" {
  type    = map(string)
  default = {}
}

variable "service_account_name" {
  type    = string
  default = "default"
}

variable "restart_policy" {
  type    = string
  default = "Always"

  validation {
    condition     = contains(["Always", "OnFailure", "Never"], var.restart_policy)
    error_message = "restart_policy must be Always, OnFailure or Never."
  }
}

variable "cpu_request" {
  type    = string
  default = "100m"
}

variable "memory_request" {
  type    = string
  default = "128Mi"
}

variable "cpu_limit" {
  type    = string
  default = "500m"
}

variable "memory_limit" {
  type    = string
  default = "512Mi"
}
