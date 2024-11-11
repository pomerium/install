locals {
  audience = var.audience == [] ? var.audience : [
    var.console_ingress.dns,
    var.console_api_ingress.dns,
  ]
  secrets_name = "enterprise"
}
