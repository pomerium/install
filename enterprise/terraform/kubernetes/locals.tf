locals {
  # keep all config parameters in one place, 
  # so that if the parameters change, we can adjust the label for a pod, 
  # that will trigger a rolling update
  config = {
    administrators         = var.administrators
    databroker_service_url = "https://pomerium-databroker.${var.core_namespace_name}.svc"
    secrets                = kubernetes_secret.console.data
    audience = var.audience == [] ? var.audience : [
      var.console_ingress.dns,
      var.console_api_ingress.dns,
    ]
    license_key_validate_offline = var.license_key_validate_offline
    prometheus_url               = var.prometheus_url
  }

  config_checksum = md5(jsonencode(local.config))

  secrets_name = "enterprise"
}
