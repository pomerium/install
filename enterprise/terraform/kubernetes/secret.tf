resource "kubernetes_secret" "console" {
  metadata {
    name      = local.secrets_name
    namespace = var.namespace_name
  }

  type = "Opaque"

  data = {
    "license_key"                 = var.license_key
    "database_url"                = var.database_url
    "database_encryption_key_b64" = random_bytes.database_encryption_key.base64
    "shared_secret_b64"           = var.shared_secret_b64
    "signing_key_b64"             = var.signing_key_b64
  }
}

resource "random_bytes" "database_encryption_key" {
  length = 32
}
