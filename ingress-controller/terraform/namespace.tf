resource "kubernetes_namespace" "pomerium" {
  count = var.use_external_namespace ? 0 : 1
  metadata {
    name   = var.namespace_name
    labels = var.labels
  }
}
