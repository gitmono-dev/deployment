output "name" {
  value = google_container_node_pool.this.name
}

output "service_account" {
  value = var.service_account != null ? var.service_account : (var.create_service_account ? google_service_account.this[0].email : null)
}

