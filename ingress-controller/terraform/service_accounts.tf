resource "kubernetes_service_account" "controller" {
  metadata {
    name      = var.controller_service_account_name
    namespace = var.namespace_name
    labels    = var.service_account_labels
  }
}

