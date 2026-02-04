resource "google_service_account" "this" {
  count = var.create_service_account ? 1 : 0

  account_id   = coalesce(var.service_account_id, "${var.name}-node-sa")
  display_name = "Node pool service account for ${var.name}"
}

resource "google_container_node_pool" "this" {
  name       = var.name
  location   = var.region
  cluster    = var.cluster_name

  initial_node_count = var.min_count > 0 ? var.min_count : 1

  dynamic "autoscaling" {
    for_each = var.enable_autoscaling ? [1] : []
    content {
      min_node_count = var.min_count
      max_node_count = var.max_count
    }
  }

  management {
    auto_repair  = true
    auto_upgrade = true
  }

  node_config {
    machine_type    = var.machine_type
    disk_size_gb    = var.disk_size_gb
    service_account = var.service_account != null ? var.service_account : (var.create_service_account ? google_service_account.this[0].email : null)
    tags            = var.tags

    labels = var.labels

    dynamic "taint" {
      for_each = var.taints
      content {
        key    = taint.value.key
        value  = taint.value.value
        effect = taint.value.effect
      }
    }

    oauth_scopes = [
      "https://www.googleapis.com/auth/cloud-platform"
    ]

    metadata = {
      disable-legacy-endpoints = "true"
    }
  }

  lifecycle {
    ignore_changes = [
      initial_node_count
    ]
  }
}

