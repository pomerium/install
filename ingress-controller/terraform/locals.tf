locals {
  default_node_selector = {
    "kubernetes.io/os" = "linux"
  }

  secrets_name = "bootstrap"
}
