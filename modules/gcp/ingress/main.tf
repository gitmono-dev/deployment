locals {
  annotations = merge(
    var.static_ip_name != null ? { "kubernetes.io/ingress.global-static-ip-name" = var.static_ip_name } : {},
    length(var.managed_certificate_domains) > 0 ? { "networking.gke.io/managed-certificates" = "${var.name}-cert" } : {}
  )
}

resource "kubernetes_manifest" "managed_cert" {
  count = length(var.managed_certificate_domains) > 0 ? 1 : 0

  manifest = {
    apiVersion = "networking.gke.io/v1"
    kind       = "ManagedCertificate"
    metadata = {
      name      = "${var.name}-cert"
      namespace = var.namespace
    }
    spec = {
      domains = var.managed_certificate_domains
    }
  }
}

resource "kubernetes_ingress_v1" "this" {
  metadata {
    name        = var.name
    namespace   = var.namespace
    annotations = local.annotations
  }

  spec {
    ingress_class_name = var.ingress_class_name

    dynamic "rule" {
      for_each = var.rules
      content {
        host = rule.value.host
        http {
          path {
            path      = "/"
            path_type = "Prefix"
            backend {
              service {
                name = rule.value.service_name
                port {
                  number = rule.value.service_port
                }
              }
            }
          }
        }
      }
    }
  }
}

