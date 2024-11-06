locals {
  default_node_selector = {
    "kubernetes.io/os" = "linux"
  }

  node_selector = merge(local.default_node_selector, var.node_selector)

  secrets_name = "bootstrap"

  default_labels = {
    "app.kubernetes.io/name"       = "pomerium-ingress-controller"
    "app.kubernetes.io/version"    = var.image_tag
    "app.kubernetes.io/managed-by" = "terraform"
  }

  default_pod_labels = {
    "app.kubernetes.io/component" = "proxy"
  }

  deployment_labels = merge(local.default_labels, var.labels)
  pod_labels        = merge(local.deployment_labels, local.default_pod_labels, var.pod_labels)
}

