output "cluster_name" {
  value = google_container_cluster.this.name
}

output "location" {
  value = google_container_cluster.this.location
}

output "endpoint" {
  value = google_container_cluster.this.endpoint
}

output "master_auth" {
  value = google_container_cluster.this.master_auth
}

output "network" {
  value = google_container_cluster.this.network
}

output "subnetwork" {
  value = google_container_cluster.this.subnetwork
}

