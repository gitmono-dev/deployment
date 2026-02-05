output "instance_name" {
  value = google_filestore_instance.this.name
}

output "file_share_name" {
  value = google_filestore_instance.this.file_shares[0].name
}

output "ip_address" {
  value = google_filestore_instance.this.networks[0].ip_addresses[0]
}
