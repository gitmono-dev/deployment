resource "google_filestore_instance" "this" {
  name     = var.name
  location = var.location
  tier     = var.tier

  file_shares {
    name        = var.file_share_name
    capacity_gb = var.capacity_gb
  }

  networks {
    network           = var.network
    modes             = ["MODE_IPV4"]
    reserved_ip_range = var.reserved_ip_range
  }
}

