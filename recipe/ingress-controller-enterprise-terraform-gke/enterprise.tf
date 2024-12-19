
locals {
  domain         = var.domain
  namespace_name = "pomerium-enterprise"
  access_annotations = {
    "ingress.pomerium.io/allow_any_authenticated_user" = "true"
  }
  console_ingress = {
    dns         = "pomerium-console.${local.domain}"
    annotations = local.access_annotations
  }
  console_api_ingress = {
    dns         = "pomerium-console-api.${local.domain}"
    annotations = local.access_annotations
  }

  enterprise_dsn = "postgres://${google_sql_user.pomerium.name}:${random_password.pomerium.result}@127.0.0.1/${google_sql_database.console.name}?sslmode=disable"
}

module "pomerium_enterprise" {
  source = "git::https://github.com/pomerium/install//enterprise/terraform/kubernetes?ref=main"

  depends_on = [
    module.pomerium_ingress_controller,
    resource.google_sql_database.console,
  ]

  administrators = var.administrators
  namespace_name = local.namespace_name

  database_url            = local.enterprise_dsn
  license_key             = var.license_key
  image_registry_password = var.image_registry_password

  console_ingress     = local.console_ingress
  console_api_ingress = local.console_api_ingress

  bootstrap_secret = {
    name      = module.pomerium_ingress_controller.bootstrap_secret.name
    namespace = module.pomerium_ingress_controller.bootstrap_secret.namespace
  }

  service_account_annotations = {
    "iam.gke.io/gcp-service-account" = google_service_account.pomerium.email
  }

  tolerations = [
    {
      key      = "kubernetes.io/arch"
      operator = "Equal"
      value    = "amd64"
      effect   = "NoSchedule"
    }
  ]
  sidecars = [
    local.sql_proxy_sidecar
  ]
}

