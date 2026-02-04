locals {
  labels = {
    app = var.name
  }
  limits = { for k, v in { cpu = var.cpu_limit, memory = var.memory_limit } : k => v if v != null }
  requests = {
    for k, v in { cpu = var.cpu_request, memory = var.memory_request } : k => v if v != null
  }
}

resource "kubernetes_deployment_v1" "this" {
  metadata {
    name      = var.name
    namespace = var.namespace
    labels    = local.labels
  }

  spec {
    replicas = var.replicas

    selector {
      match_labels = local.labels
    }

    template {
      metadata {
        labels = local.labels
      }

      spec {
        service_account_name = var.service_account_name

        dynamic "volume" {
          for_each = var.volumes
          content {
            name = volume.value.name
            nfs {
              server = volume.value.nfs_server
              path   = volume.value.nfs_path
            }
          }
        }

        container {
          name  = var.name
          image = var.image

          port {
            container_port = var.container_port
          }

          dynamic "env" {
            for_each = var.env
            content {
              name  = env.value.name
              value = env.value.value
            }
          }

          dynamic "volume_mount" {
            for_each = var.volume_mounts
            content {
              name       = volume_mount.value.name
              mount_path = volume_mount.value.mount_path
              read_only  = volume_mount.value.read_only
            }
          }

          resources {
            limits   = local.limits
            requests = local.requests
          }
        }
      }
    }
  }
}

resource "kubernetes_service_v1" "this" {
  metadata {
    name      = var.name
    namespace = var.namespace
    labels    = local.labels
  }

  spec {
    selector = local.labels
    type     = var.service_type

    port {
      port        = var.container_port
      target_port = var.container_port
      protocol    = "TCP"
    }
  }
}

resource "kubernetes_horizontal_pod_autoscaler_v2" "this" {
  count = var.enable_hpa ? 1 : 0

  metadata {
    name      = "${var.name}-hpa"
    namespace = var.namespace
  }

  spec {
    min_replicas = var.hpa_min_replicas
    max_replicas = var.hpa_max_replicas

    scale_target_ref {
      api_version = "apps/v1"
      kind        = "Deployment"
      name        = kubernetes_deployment_v1.this.metadata[0].name
    }

    metric {
      type = "Resource"
      resource {
        name = "cpu"
        target {
          type                = "Utilization"
          average_utilization = var.hpa_cpu_utilization
        }
      }
    }
  }
}
