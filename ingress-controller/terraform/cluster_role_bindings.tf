resource "kubernetes_cluster_role_binding" "controller" {
  metadata {
    name   = var.controller_cluster_role_name
    labels = var.cluster_role_labels
  }

  role_ref {
    api_group = "rbac.authorization.k8s.io"
    kind      = "ClusterRole"
    name      = kubernetes_cluster_role.controller.metadata[0].name
  }

  subject {
    kind      = "ServiceAccount"
    name      = kubernetes_service_account.controller.metadata[0].name
    namespace = var.namespace_name
  }
}

