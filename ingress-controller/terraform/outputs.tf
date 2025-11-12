output "shared_secret_b64" {
  value     = random_bytes.shared_secret.base64
  sensitive = true
}

output "signing_key_b64" {
  value     = base64encode(tls_private_key.signing_key.private_key_pem)
  sensitive = true
}
