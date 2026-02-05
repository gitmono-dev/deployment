resource "google_compute_global_address" "private_service_range" {
  count         = var.enable_private_service_connection ? 1 : 0
  name          = "${var.name}-private-range"
  purpose       = "VPC_PEERING"
  address_type  = "INTERNAL"
  prefix_length = var.private_ip_prefix_length
  network       = var.private_network
}

resource "google_service_networking_connection" "private_vpc_connection" {
  count                   = var.enable_private_service_connection ? 1 : 0
  network                 = var.private_network
  service                 = "servicenetworking.googleapis.com"
  reserved_peering_ranges = [google_compute_global_address.private_service_range[0].name]
}

resource "google_sql_database_instance" "this" {
  name                = var.name
  database_version    = var.database_version
  region              = var.region
  deletion_protection = var.deletion_protection

  settings {
    tier              = var.tier
    availability_type = var.availability_type
    disk_size         = var.disk_size
    disk_type         = var.disk_type

    backup_configuration {
      enabled = var.backup_enabled
    }

    ip_configuration {
      ipv4_enabled    = var.enable_public_ip
      private_network = var.private_network
    }
  }

  depends_on = [google_service_networking_connection.private_vpc_connection]
}

resource "google_sql_database" "db" {
  name     = var.db_name
  instance = google_sql_database_instance.this.name
}

resource "google_sql_user" "user" {
  name     = var.db_username
  instance = google_sql_database_instance.this.name
  password = var.db_password
}

