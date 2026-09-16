package dn.globalautomation.terraform

# Conftest evaluates Terraform plan JSON. These are deliberately baseline
# guardrails; DN-specific policies can be added without changing the pipeline.

deny[msg] {
  resource := input.resource_changes[_]
  resource.type == "kubernetes_pod_v1"
  image := resource.change.after.spec[0].container[0].image
  endswith(image, ":latest")
  msg := sprintf("Pod %s uses mutable :latest image tag", [resource.address])
}

deny[msg] {
  resource := input.resource_changes[_]
  resource.type == "kubernetes_pod_v1"
  limits := resource.change.after.spec[0].container[0].resources[0].limits
  count(limits) == 0
  msg := sprintf("Pod %s has no resource limits", [resource.address])
}
