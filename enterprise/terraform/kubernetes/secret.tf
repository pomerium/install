resource "kubernetes_secret" "console" {
  metadata {
    name      = local.secrets_name
    namespace = var.namespace_name
  }

  depends_on = [data.kubernetes_secret.core_secrets]

  type = "Opaque"

  data = {
    "license_key"                 = var.license_key
    "database_url"                = var.database_url
    "database_encryption_key_b64" = random_bytes.database_encryption_key.base64
    "shared_secret_b64"           = data.kubernetes_secret.core_secrets.binary_data["shared_secret"]
    "signing_key_b64"             = data.kubernetes_secret.core_secrets.binary_data["signing_key"]
    "rv"                          = data.kubernetes_secret.core_secrets.metadata[0].resource_version
  }
}

resource "random_bytes" "database_encryption_key" {
  length = 32
}

data "kubernetes_secret" "core_secrets" {
  metadata {
    name      = var.bootstrap_secret.name
    namespace = var.bootstrap_secret.namespace
  }
  binary_data = {
    shared_secret = ""
    signing_key   = ""
  }
}
