resource "kubernetes_deployment" "pomerium-console" {
  metadata {
    name      = "pomerium-console"
    namespace = var.namespace_name
  }

  depends_on = [
    kubernetes_namespace.pomerium-enterprise,
    kubernetes_secret.console,
    kubernetes_secret.docker_registry,
    kubernetes_secret.console,
  ]

  lifecycle {
    ignore_changes = [
      metadata[0].annotations,
    ]
  }

  spec {
    replicas = var.deployment_replicas

    selector {
      match_labels = {
        "app.kubernetes.io/name" = "pomerium-console"
      }
    }

    template {
      metadata {
        labels = {
          "app.kubernetes.io/name"      = "pomerium-console"
          "pomerium.io/config-checksum" = local.config_checksum
        }
      }

      spec {
        termination_grace_period_seconds = 30

        service_account_name = kubernetes_service_account.console.metadata[0].name

        security_context {
          run_as_non_root = true

          seccomp_profile {
            type = "RuntimeDefault"
          }
        }

        os {
          name = "linux"
        }

        node_selector = {
          "kubernetes.io/os" = "linux"
        }

        image_pull_secrets {
          name = var.image_pull_secret
        }

        volume {
          name = "tmp"
          empty_dir {
            size_limit = var.resources_ephemeral_storage
          }
        }

        dynamic "toleration" {
          for_each = var.tolerations
          content {
            key                = lookup(toleration.value, "key", null)
            operator           = lookup(toleration.value, "operator", null)
            value              = lookup(toleration.value, "value", null)
            effect             = lookup(toleration.value, "effect", null)
            toleration_seconds = lookup(toleration.value, "toleration_seconds", null)
          }
        }

        container {
          name              = "pomerium-console"
          image             = "${var.image_registry}/${var.image_name}:${var.image_tag}"
          image_pull_policy = var.image_pull_policy

          args = [
            "--tls-derive=pomerium-console.${var.namespace_name}.svc.cluster.local",
            "--metrics-addr=$(POD_IP):9090",
            "serve",
          ]

          env {
            name  = "AUDIENCE"
            value = join(",", local.config.audience)
          }

          env {
            name  = "ADMINISTRATORS"
            value = join(",", local.config.administrators)
          }

          env {
            name  = "DATABROKER_SERVICE_URL"
            value = local.config.databroker_service_url
          }

          env {
            name = "SHARED_SECRET"
            value_from {
              secret_key_ref {
                name = local.secrets_name
                key  = "shared_secret_b64"
              }
            }
          }

          env {
            name = "SIGNING_KEY"
            value_from {
              secret_key_ref {
                name = local.secrets_name
                key  = "signing_key_b64"
              }
            }
          }

          env {
            name = "DATABASE_URL"
            value_from {
              secret_key_ref {
                name     = local.secrets_name
                key      = "database_url"
                optional = false
              }
            }
          }

          env {
            name = "DATABASE_ENCRYPTION_KEY"
            value_from {
              secret_key_ref {
                name     = local.secrets_name
                key      = "database_encryption_key_b64"
                optional = false
              }
            }
          }

          env {
            name = "LICENSE_KEY"
            value_from {
              secret_key_ref {
                name     = local.secrets_name
                key      = "license_key"
                optional = false
              }
            }
          }

          env {
            name  = "LICENSE_KEY_VALIDATE_OFFLINE"
            value = local.config.license_key_validate_offline
          }

          env {
            name  = "PROMETHEUS_URL"
            value = local.config.prometheus_url
          }

          env {
            name  = "TMPDIR"
            value = "/tmp"
          }

          env {
            name  = "XDG_CACHE_HOME"
            value = "/tmp"
          }

          env {
            name  = "VALIDATION_MODE"
            value = var.validation_mode
          }

          env {
            name = "POD_IP"
            value_from {
              field_ref {
                field_path = "status.podIP"
              }
            }
          }

          env {
            name  = "BOOTSTRAP_SERVICE_ACCOUNT"
            value = var.bootstrap_service_account
          }

          volume_mount {
            name       = "tmp"
            mount_path = "/tmp"
          }

          port {
            name           = "app"
            container_port = 8701
            protocol       = "TCP"
          }

          port {
            name           = "grpc-api"
            container_port = 8702
            protocol       = "TCP"
          }

          port {
            name           = "metrics"
            container_port = 9090
            protocol       = "TCP"
          }

          resources {
            limits = {
              cpu                 = var.resources_limits_cpu
              memory              = var.resources_limits_memory
              "ephemeral-storage" = var.resources_ephemeral_storage
            }
            requests = {
              cpu                 = var.resources_requests_cpu
              memory              = var.resources_requests_memory
              "ephemeral-storage" = var.resources_ephemeral_storage
            }
          }

          security_context {
            read_only_root_filesystem = true
            capabilities {
              drop = ["ALL"]
              add  = []
            }
            allow_privilege_escalation = false
          }
        }

        dynamic "container" {
          for_each = var.sidecars
          content {
            name  = container.value.name
            image = container.value.image
            args  = container.value.args
            security_context {
              run_as_non_root            = true
              allow_privilege_escalation = false
              read_only_root_filesystem  = true
              capabilities {
                drop = ["ALL"]
                add  = []
              }
            }
          }
        }
      }
    }
  }
}
