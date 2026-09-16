output "pod_name" {
  value = kubernetes_pod_v1.this.metadata[0].name
}

output "namespace" {
  value = kubernetes_pod_v1.this.metadata[0].namespace
}
