module "pomerium_ingress_controller" {
  source = "git::https://github.com/pomerium/install//ingress-controller/terraform?ref=main"

  enable_databroker = true
  image_tag         = "main"
  image_pull_policy = "Always"
}

data "kubernetes_secret" "pomerium_bootstrap" {
  metadata {
    name      = module.pomerium_ingress_controller.bootstrap_secret.name
    namespace = module.pomerium_ingress_controller.bootstrap_secret.namespace
  }
}
