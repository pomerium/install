resource "kubernetes_service_account" "controller" {
  metadata {
    name      = var.controller_service_account_name
    namespace = locals.namespace_name
    labels    = var.service_account_labels
  }
}

resource "kubernetes_service_account" "gen_secrets" {
  metadata {
    name      = var.gen_secrets_service_account_name
    namespace = locals.namespace_name
    labels    = var.service_account_labels
  }
}
