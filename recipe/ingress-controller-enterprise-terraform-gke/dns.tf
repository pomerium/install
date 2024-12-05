data "kubernetes_service" "pomerium_proxy" {
  metadata {
    name      = "pomerium-proxy"
    namespace = "pomerium-ingress-controller"
  }
  depends_on = [module.pomerium_ingress_controller]
}

locals {
  load_balancer_ip = data.kubernetes_service.pomerium_proxy.status[0].load_balancer[0].ingress[0].ip
}

resource "google_dns_record_set" "wildcard_record" {
  count        = local.load_balancer_ip != null && var.update_cloud_dns_zone != null ? 1 : 0
  name         = "*.${local.domain}."
  type         = "A"
  ttl          = 300
  managed_zone = var.update_cloud_dns_zone

  rrdatas = [local.load_balancer_ip]
}
