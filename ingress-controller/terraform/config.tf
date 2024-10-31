resource "kubectl_manifest" "pomerium_config" {
  count = local.create_config ? 1 : 0

  depends_on = [kubectl_manifest.pomerium_crd]
  yaml_body = yamlencode({
    apiVersion = "ingress.pomerium.io/v1"
    kind       = "Pomerium"
    metadata = {
      name = "${var.pomerium_config_name}"
    }
    spec = {
      secrets = "${var.namespace_name}/${local.secrets_name}"
      identityProvider = local.idp_config != null ? {
        provider = local.idp_config.provider
        secret   = "${var.namespace_name}/${local.idp_secret_name}"
        url      = local.idp_config.url
      } : null
    }
  })
}

resource "kubernetes_secret" "idp" {
  count = local.create_config ? 1 : 0

  metadata {
    name      = local.idp_secret_name
    namespace = var.namespace_name
  }

  data = {
    client_id     = local.idp_config.client_id
    client_secret = local.idp_config.client_secret
  }
}

locals {
  create_config   = true
  idp_secret_name = "idp"
  idp_config      = try(coalesce(local.idp_azure), null)
  idp_azure = var.idp_azure != null ? {
    provider      = "azure"
    client_id     = var.idp_azure.client_id
    client_secret = var.idp_azure.client_secret
    url           = "https://login.microsoftonline.com/${var.idp_azure.tenant_id}/v2.0"
  } : null
}
