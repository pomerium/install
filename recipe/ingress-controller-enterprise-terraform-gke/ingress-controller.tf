
module "pomerium_ingress_controller" {
  source = "git::https://github.com/pomerium/install//ingress-controller/terraform?ref=main"

  enable_databroker = true
  image_tag         = var.ingress_controller_image_tag

  use_clustered_databroker          = var.use_clustered_databroker
  clustered_databroker_cluster_size = var.clustered_databroker_cluster_size
}

data "kubernetes_secret" "pomerium_bootstrap" {
  metadata {
    name      = module.pomerium_ingress_controller.bootstrap_secret.name
    namespace = module.pomerium_ingress_controller.bootstrap_secret.namespace
  }
}
