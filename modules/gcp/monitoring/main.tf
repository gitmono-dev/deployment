locals {
  enable_logging    = var.enable_logging
  enable_monitoring = var.enable_monitoring
  enable_alerts     = var.enable_alerts
}

resource "google_project_service" "logging" {
  count   = local.enable_logging ? 1 : 0
  project = var.project_id
  service = "logging.googleapis.com"
}

resource "google_project_service" "monitoring" {
  count   = local.enable_monitoring ? 1 : 0
  project = var.project_id
  service = "monitoring.googleapis.com"
}

resource "google_logging_project_sink" "this" {
  count       = var.log_sink_name != "" && var.log_sink_destination != "" ? 1 : 0
  name        = var.log_sink_name
  project     = var.project_id
  destination = var.log_sink_destination
  filter      = "resource.type=\"k8s_container\""
}

resource "google_monitoring_alert_policy" "pod_restart_high" {
  count          = local.enable_alerts ? 1 : 0
  display_name   = "GKE Pod Restart Rate High"
  combiner       = "OR"
  enabled        = true
  notification_channels = var.alert_notification_channels

  conditions {
    display_name = "Pod restart rate > 5/min"
    condition_threshold {
      filter          = "metric.type=\"kubernetes.io/container/restart_count\" resource.type=\"k8s_container\""
      duration        = "300s"
      comparison      = "COMPARISON_GT"
      threshold_value = 5
      aggregations {
        alignment_period     = "60s"
        per_series_aligner   = "ALIGN_RATE"
        cross_series_reducer = "REDUCE_SUM"
        group_by_fields      = ["resource.label.namespace_name", "resource.label.pod_name", "resource.label.container_name"]
      }
    }
  }

  documentation {
    content = "High pod restart rate detected. Check pod logs and events."
  }
}

resource "google_monitoring_alert_policy" "sql_connection_failures" {
  count          = local.enable_alerts ? 1 : 0
  display_name   = "Cloud SQL Connection Failures"
  combiner       = "OR"
  enabled        = true
  notification_channels = var.alert_notification_channels

  conditions {
    display_name = "SQL connection errors > 0"
    condition_threshold {
      filter          = "metric.type=\"cloudsql.googleapis.com/database/network/received_bytes_count\" resource.type=\"cloudsql_database\""
      duration        = "300s"
      comparison      = "COMPARISON_GT"
      threshold_value = 0
      aggregations {
        alignment_period     = "60s"
        per_series_aligner   = "ALIGN_RATE"
        cross_series_reducer = "REDUCE_SUM"
        group_by_fields      = ["resource.label.database_id"]
      }
    }
  }

  documentation {
    content = "Cloud SQL connection issues detected. Check network connectivity and IAM permissions."
  }
}

