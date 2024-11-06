output "bootstrap_secret" {
  value = {
    name      = kubernetes_secret.bootstrap.metadata[0].name
    namespace = kubernetes_secret.bootstrap.metadata[0].namespace
  }
}
