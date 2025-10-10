resource "kubernetes_deployment" "pomerium" {
  metadata {
    name      = var.deployment_name
    namespace = var.namespace_name
    labels = merge(local.deployment_labels, {
      "app.kubernetes.io/component" = "proxy"
    })
  }

  depends_on = [
    kubernetes_secret.bootstrap
  ]

  lifecycle {
    ignore_changes = [
      metadata[0].annotations,
      spec[0].template[0].metadata[0].annotations,
      spec[0].template[0].spec[0].container[0].resources,
      spec[0].template[0].spec[0].container[0].security_context,
      spec[0].template[0].spec[0].toleration,
      spec[0].template[0].spec[0].security_context,
    ]
  }

  spec {
    replicas          = var.deployment_replicas
    min_ready_seconds = var.min_ready_seconds

    strategy {
      type = "RollingUpdate"
      rolling_update {
        max_surge       = var.rolling_update.max_surge
        max_unavailable = var.rolling_update.max_unavailable
      }
    }

    selector {
      match_labels = local.pod_labels
    }

    template {
      metadata {
        labels = local.pod_labels
      }

      spec {
        service_account_name             = kubernetes_service_account.controller.metadata[0].name
        termination_grace_period_seconds = 10

        security_context {
          run_as_non_root = true
        }

        node_selector = local.node_selector

        container {
          name              = "pomerium-ingress-controller"
          image             = "${var.image_repository}:${var.image_tag}"
          image_pull_policy = var.image_pull_policy
          startup_probe {
            failure_threshold = 40
            period_seconds = 15
            http_get {
              path = "/startupz"
              port = 28080
            }
          }

          liveness_probe {
            failure_threshold = 10
            period_seconds = 60
            initial_delay_seconds = 15
            http_get {
              path = "/healthz"
              port = 28080
            }

          }
          readiness_probe {
             failure_threshold = 5
             initial_delay_seconds = 15
             period_seconds = 60
             http_get {
               path = "/readyz"
               port = 28080
             }
          }

          args = concat(
            [
              "all-in-one",
              "--pomerium-config=${var.pomerium_config_name}",
              "--update-status-from-service=${var.namespace_name}/pomerium-proxy",
              "--metrics-bind-address=$(POD_IP):9090",
              "--health-probe-bind-address=$(POD_IP):28080"
            ],
            var.use_clustered_databroker ? concat(
              [
                "--databroker-auto-tls=*.pomerium-databroker.${var.namespace_name}.svc",
                "--services=authenticate,authorize,proxy"
              ],
              [
                for i in range(var.clustered_databroker_cluster_size) :
                "--databroker-service-urls=https://pomerium-databroker-${i}.pomerium-databroker.${var.namespace_name}.svc:5443"
              ]
            ) :
            var.enable_databroker ? [
              "--databroker-auto-tls=pomerium-databroker.${var.namespace_name}.svc"
            ] : []
          )

          env {
            name  = "TMPDIR"
            value = "/tmp"
          }

          env {
            name  = "XDG_CACHE_HOME"
            value = "/tmp"
          }

          env {
            name = "POD_IP"
            value_from {
              field_ref {
                field_path = "status.podIP"
              }
            }
          }

          port {
            container_port = 8443
            name           = "https"
            protocol       = "TCP"
          }

          port {
            container_port = 8080
            name           = "http"
            protocol       = "TCP"
          }

          port {
            container_port = 9090
            name           = "metrics"
            protocol       = "TCP"
          }

          dynamic "port" {
            for_each = var.enable_databroker ? [1] : []
            content {
              container_port = 5443
              name           = "grpc"
              protocol       = "TCP"
            }
          }

          dynamic "port" {
            for_each = var.enable_databroker ? [1] : []
            content {
              container_port = 5999
              name           = "raft"
              protocol       = "TCP"
            }
          }

          resources {
            limits = {
              cpu    = var.resources_limits_cpu
              memory = var.resources_limits_memory
            }

            requests = {
              cpu    = var.resources_requests_cpu
              memory = var.resources_requests_memory
            }
          }

          security_context {
            allow_privilege_escalation = false
            read_only_root_filesystem  = true
            run_as_group               = 65532
            run_as_non_root            = true
            run_as_user                = 65532
          }

          volume_mount {
            name       = "tmp"
            mount_path = "/tmp"
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

        volume {
          name = "tmp"

          empty_dir {}
        }
      }
    }
  }
}
