locals {
  default_ingress_annotations = {
    "ingress.pomerium.io/pass_identity_headers" = "true"
    "ingress.pomerium.io/secure_upstream"       = "true"
  }
}

resource "kubernetes_ingress_v1" "console" {
  count = var.console_ingress != null ? 1 : 0
  metadata {
    name        = "console"
    namespace   = var.namespace_name
    annotations = merge(local.default_ingress_annotations, var.console_ingress.annotations)
  }

  spec {
    ingress_class_name = var.ingress_class_name

    rule {
      host = var.console_ingress.dns

      http {
        path {
          path      = "/"
          path_type = "Prefix"
          backend {
            service {
              name = resource.kubernetes_service.console.metadata[0].name
              port {
                name = "https"
              }
            }
          }
        }
      }
    }
  }
}

resource "kubernetes_ingress_v1" "console-api" {
  count = var.console_api_ingress != null ? 1 : 0
  metadata {
    name      = "console-api"
    namespace = var.namespace_name
    annotations = merge(
      local.default_ingress_annotations,
      var.console_api_ingress.annotations,
    )
  }

  spec {
    ingress_class_name = var.ingress_class_name

    rule {
      host = var.console_api_ingress.dns

      http {
        path {
          path      = "/"
          path_type = "Prefix"
          backend {
            service {
              name = resource.kubernetes_service.console.metadata[0].name
              port {
                name = "grpc"
              }
            }
          }
        }
      }
    }
  }
}
