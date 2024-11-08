resource "kubectl_manifest" "pomerium_config" {
  count = local.config != null ? 1 : 0

  depends_on = [kubectl_manifest.pomerium_crd]
  yaml_body = yamlencode({
    apiVersion = "ingress.pomerium.io/v1"
    kind       = "Pomerium"
    metadata = {
      name = "${var.pomerium_config_name}"
    }
    spec = local.config
  })
}

locals {
  default_config = {
    secrets = "${var.namespace_name}/${local.secrets_name}"
  }

  config = var.config != null ? merge(local.default_config, var.config) : null
}
