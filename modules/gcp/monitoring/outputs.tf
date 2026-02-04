output "logging_api_enabled" {
  description = "Whether Cloud Logging API is enabled"
  value       = length(google_project_service.logging) > 0
}

output "monitoring_api_enabled" {
  description = "Whether Cloud Monitoring API is enabled"
  value       = length(google_project_service.monitoring) > 0
}

output "log_sink_writer_identity" {
  description = "Writer identity for the optional log sink"
  value       = try(google_logging_project_sink.this[0].writer_identity, null)
}

output "alert_policy_ids" {
  description = "Created alert policy IDs"
  value = {
    pod_restart_high       = try(google_monitoring_alert_policy.pod_restart_high[0].name, null)
    sql_connection_failures = try(google_monitoring_alert_policy.sql_connection_failures[0].name, null)
  }
}

