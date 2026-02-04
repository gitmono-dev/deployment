output "ingress_name" {
  value = kubernetes_ingress_v1.this.metadata[0].name
}

output "ip_address" {
  value = try(kubernetes_ingress_v1.this.status[0].load_balancer[0].ingress[0].ip, null)
}

output "hostname" {
  value = try(kubernetes_ingress_v1.this.status[0].load_balancer[0].ingress[0].hostname, null)
}

