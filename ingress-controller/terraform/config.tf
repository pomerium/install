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
  default_config = merge(
    {
      secrets = "${var.namespace_name}/${local.secrets_name}"
    },
    var.use_clustered_databroker ? {
      storage = {
        file = {
          path = "/var/pomerium/databroker"
        }
      }
    } :
    {},
  )

  config = var.config != null ? merge(local.default_config, {
    for k, v in var.config : k => v if v != null
  }) : null
}
