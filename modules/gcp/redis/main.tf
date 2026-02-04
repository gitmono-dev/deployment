resource "google_redis_instance" "this" {
  name                    = var.name
  region                  = var.region
  tier                    = var.tier
  memory_size_gb          = var.memory_size_gb
  authorized_network      = var.network
  transit_encryption_mode = var.transit_encryption_mode
}

