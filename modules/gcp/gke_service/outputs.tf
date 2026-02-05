output "service_name" {
  value = kubernetes_service_v1.this.metadata[0].name
}

output "service_port" {
  value = kubernetes_service_v1.this.spec[0].port[0].port
}

output "deployment_name" {
  value = kubernetes_deployment_v1.this.metadata[0].name
}

