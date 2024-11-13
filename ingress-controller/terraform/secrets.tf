resource "kubernetes_secret" "bootstrap" {
  metadata {
    name      = local.secrets_name
    namespace = var.namespace_name
  }

  type = "Opaque"

  binary_data = {
    "shared_secret" = random_bytes.shared_secret.base64
    "cookie_secret" = random_bytes.cookie_secret.base64
  }

  data = {
    "signing_key" = tls_private_key.signing_key.private_key_pem
  }
}

resource "tls_private_key" "signing_key" {
  algorithm   = "ECDSA"
  ecdsa_curve = "P256"
}

resource "random_bytes" "shared_secret" {
  length = 32
  lifecycle {
    create_before_destroy = true
  }
  keepers = {
    version = var.secrets_version
  }
}

resource "random_bytes" "cookie_secret" {
  length = 32
  lifecycle {
    create_before_destroy = true
  }
  keepers = {
    version = var.secrets_version
  }
}

