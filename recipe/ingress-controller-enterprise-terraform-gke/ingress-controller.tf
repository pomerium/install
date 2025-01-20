module "pomerium_ingress_controller" {
  source = "git::https://github.com/pomerium/install//ingress-controller/terraform?ref=main"

  enable_databroker = true
  image_tag         = "sha-8c71989" # pending https://linear.app/pomerium/issue/ENG-1865/installingress-controller-update-ports-in-terraform
  image_pull_policy = "IfNotPresent"
}

data "kubernetes_secret" "pomerium_bootstrap" {
  metadata {
    name      = module.pomerium_ingress_controller.bootstrap_secret.name
    namespace = module.pomerium_ingress_controller.bootstrap_secret.namespace
  }
}
