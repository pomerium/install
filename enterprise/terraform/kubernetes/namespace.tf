resource "kubernetes_namespace" "pomerium-enterprise" {
  count = var.use_external_namespace ? 0 : 1
  metadata {
    name = var.namespace_name
  }
}
