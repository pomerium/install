resource "kubernetes_stateful_set_v1" "pomerium-databroker" {
  count = var.use_clustered_databroker ? 1 : 0

  metadata {
    namespace = var.namespace_name
    name      = "pomerium-databroker"
    labels = merge(local.deployment_labels, {
      "app.kubernetes.io/component" = "databroker"
    })
  }


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
    selector {
      match_labels = {
        "app.kubernetes.io/name"      = "pomerium-ingress-controller"
        "app.kubernetes.io/component" = "databroker"
      }
    }
    service_name          = "pomerium-databroker"
    replicas              = var.clustered_databroker_cluster_size
    pod_management_policy = "Parallel"
    update_strategy {
      type = "RollingUpdate"
    }
    persistent_volume_claim_retention_policy {
      when_deleted = "Delete"
      when_scaled  = "Delete"
    }
    template {
      metadata {
        labels = merge(local.pod_labels, {
          "app.kubernetes.io/component" = "databroker"
        })
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
          args = [
            "all-in-one",
            "--pomerium-config=${var.pomerium_config_name}",
            "--metrics-bind-address=$(POD_IP):9090",
            "--services=databroker",
            "--databroker-cluster-node-id=$(POD_NAME)",
            "--databroker-raft-bind-address=:5999",
            "--databroker-auto-tls=*.pomerium-databroker.${var.namespace_name}.svc",
          ]
          env {
            name = "POMERIUM_NAMESPACE"
            value_from {
              field_ref {
                api_version = "v1"
                field_path  = "metadata.namespace"
              }
            }
          }
          env {
            name = "POD_IP"
            value_from {
              field_ref {
                api_version = "v1"
                field_path  = "status.podIP"
              }
            }
          }
          env {
            name = "POD_NAME"
            value_from {
              field_ref {
                field_path = "metadata.name"
              }
            }
          }
          env {
            name = "DATABROKER_CLUSTER_NODES"
            value = jsonencode([
              for i in range(var.clustered_databroker_cluster_size) : {
                id           = "pomerium-databroker-${i}"
                grpc_address = "https://pomerium-databroker-${i}.pomerium-databroker.${var.namespace_name}.svc:5443"
                raft_address = "pomerium-databroker-${i}.pomerium-databroker.${var.namespace_name}.svc:5999"
              }
            ])
          }
        }
      }
    }
  }
}
