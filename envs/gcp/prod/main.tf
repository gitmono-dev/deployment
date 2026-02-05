locals {
  enable_build_env = var.enable_build_env
  enable_gcs       = var.enable_gcs
  enable_cloud_sql = var.enable_cloud_sql
  enable_redis     = var.enable_redis
  enable_filestore = var.enable_filestore
  enable_apps      = var.enable_apps
  enable_ingress   = var.enable_ingress
}

module "network" {
  count  = local.enable_build_env ? 1 : 0
  source = "../../../modules/gcp/network"

  name_prefix              = var.name_prefix
  region                   = var.region
  network_name             = var.network_name
  subnet_name              = var.subnet_name
  subnet_cidr              = var.subnet_cidr
  pods_secondary_range     = var.pods_secondary_range
  services_secondary_range = var.services_secondary_range
}

module "artifact_registry" {
  count  = local.enable_build_env ? 1 : 0
  source = "../../../modules/gcp/artifact_registry"

  location  = var.artifact_registry_location
  repo_name = var.artifact_registry_repo
}

module "gke" {
  count  = local.enable_build_env ? 1 : 0
  source = "../../../modules/gcp/gke"

  project_id   = var.project_id
  region       = var.region
  cluster_name = var.cluster_name

  network_self_link    = module.network[0].network_self_link
  subnetwork_self_link = module.network[0].subnetwork_self_link

  ip_range_pods_name     = module.network[0].pods_secondary_range_name
  ip_range_services_name = module.network[0].services_secondary_range_name

  logging_service    = var.enable_logging ? "logging.googleapis.com/kubernetes" : "none"
  monitoring_service = var.enable_monitoring ? "monitoring.googleapis.com/kubernetes" : "none"
}

module "nodepool" {
  count  = local.enable_build_env ? 1 : 0
  source = "../../../modules/gcp/gke/nodepool"

  project_id   = var.project_id
  region       = var.region
  cluster_name = module.gke[0].cluster_name

  name         = var.nodepool_name
  machine_type = var.node_machine_type
  disk_size_gb = var.node_disk_size_gb

  min_count = var.node_min_count
  max_count = var.node_max_count

  labels = {
    nodepool = var.nodepool_name
  }

  taints = [
    {
      key    = "dedicated"
      value  = "orion-build"
      effect = "NO_SCHEDULE"
    }
  ]
}

module "iam" {
  source = "../../../modules/gcp/iam"

  project_id       = var.project_id
  prefix           = coalesce(var.app_suffix, var.name_prefix)
  service_accounts = var.iam_service_accounts
}

module "monitoring" {
  source = "../../../modules/gcp/monitoring"

  project_id                  = var.project_id
  enable_logging              = var.enable_logging
  enable_monitoring           = var.enable_monitoring
  enable_alerts               = var.enable_alerts
  alert_notification_channels  = var.alert_notification_channels
  log_sink_name               = var.log_sink_name
  log_sink_destination        = var.log_sink_destination
}

module "gcs" {
  count  = local.enable_gcs ? 1 : 0
  source = "../../../modules/gcp/gcs"

  name                     = var.gcs_bucket
  location                 = var.region
  force_destroy            = var.gcs_force_destroy
  uniform_bucket_level_access = var.gcs_uniform_bucket_level_access
}

module "cloud_sql" {
  count  = local.enable_cloud_sql ? 1 : 0
  source = "../../../modules/gcp/cloud_sql"

  name                     = var.cloud_sql_instance_name
  database_version         = var.cloud_sql_database_version
  region                   = var.region
  tier                     = var.cloud_sql_tier
  disk_size                = var.cloud_sql_disk_size
  disk_type                = var.cloud_sql_disk_type
  availability_type        = var.cloud_sql_availability_type
  private_network          = local.enable_build_env ? module.network[0].network_self_link : ""
  private_ip_prefix_length = var.cloud_sql_private_ip_prefix_length
  enable_private_service_connection = var.cloud_sql_enable_private_service_connection
  enable_public_ip         = var.cloud_sql_enable_public_ip
  db_name                  = var.cloud_sql_db_name
  db_username              = var.db_username
  db_password              = var.db_password
  backup_enabled           = var.cloud_sql_backup_enabled
  deletion_protection      = var.cloud_sql_deletion_protection
}

module "redis" {
  count  = local.enable_redis ? 1 : 0
  source = "../../../modules/gcp/redis"

  name                    = var.redis_instance_name
  region                  = var.region
  tier                    = var.redis_tier
  memory_size_gb          = var.redis_memory_size_gb
  network                 = local.enable_build_env ? module.network[0].network_self_link : ""
  transit_encryption_mode = var.redis_transit_encryption_mode
}

module "filestore" {
  count  = local.enable_filestore ? 1 : 0
  source = "../../../modules/gcp/filestore"

  name           = var.filestore_instance_name
  location       = var.zone != "" ? var.zone : "${var.region}-b"
  network        = local.enable_build_env ? module.network[0].network_self_link : ""
  tier           = var.filestore_tier
  capacity_gb    = var.filestore_capacity_gb
  file_share_name = var.filestore_file_share_name
  reserved_ip_range = var.filestore_reserved_ip_range
}

module "gke_service" {
  count  = local.enable_apps ? 1 : 0
  source = "../../../modules/gcp/gke_service"

  name           = var.app_service_name
  namespace      = var.app_namespace
  image          = var.app_image
  container_port = var.app_container_port
  env            = var.app_env
  volumes        = var.app_volumes
  volume_mounts  = var.app_volume_mounts
  replicas       = var.app_replicas
  service_type   = var.app_service_type
  cpu_request    = var.app_cpu_request
  memory_request = var.app_memory_request
  cpu_limit      = var.app_cpu_limit
  memory_limit   = var.app_memory_limit
  enable_hpa     = var.app_enable_hpa
  hpa_min_replicas = var.app_hpa_min_replicas
  hpa_max_replicas = var.app_hpa_max_replicas
  hpa_cpu_utilization = var.app_hpa_cpu_utilization
}

module "ingress" {
  count  = local.enable_ingress ? 1 : 0
  source = "../../../modules/gcp/ingress"

  name                    = var.ingress_name
  namespace               = var.ingress_namespace
  static_ip_name          = var.ingress_static_ip_name
  ingress_class_name      = var.ingress_class_name
  managed_certificate_domains = var.ingress_managed_certificate_domains
  rules                   = var.ingress_rules
}

output "gke_cluster_name" {
  value = local.enable_build_env ? module.gke[0].cluster_name : null
}

output "gke_cluster_location" {
  value = local.enable_build_env ? module.gke[0].location : null
}

output "artifact_registry_repo" {
  value = local.enable_build_env ? module.artifact_registry[0].repository : null
}

output "gcs_bucket_name" {
  value = local.enable_gcs ? module.gcs[0].bucket_name : null
}

output "cloud_sql_db_endpoint" {
  value = local.enable_cloud_sql ? module.cloud_sql[0].db_endpoint : null
}

output "cloud_sql_connection_name" {
  value = local.enable_cloud_sql ? module.cloud_sql[0].connection_name : null
}

output "redis_host" {
  value = local.enable_redis ? module.redis[0].host : null
}

output "redis_port" {
  value = local.enable_redis ? module.redis[0].port : null
}

output "pg_endpoint" {
  value = local.enable_cloud_sql ? module.cloud_sql[0].db_endpoint : null
}

output "valkey_endpoint" {
  value = local.enable_redis ? [{ address = module.redis[0].host, port = module.redis[0].port }] : null
}

output "alb_dns_name" {
  value = local.enable_ingress ? coalesce(module.ingress[0].ip_address, module.ingress[0].hostname) : null
}

output "filestore_instance_name" {
  value = local.enable_filestore ? module.filestore[0].instance_name : null
}

output "filestore_file_share_name" {
  value = local.enable_filestore ? module.filestore[0].file_share_name : null
}

output "filestore_ip_address" {
  value = local.enable_filestore ? module.filestore[0].ip_address : null
}

output "iam_service_accounts" {
  description = "Created service accounts with emails and names"
  value       = module.iam.service_accounts
}

output "iam_workload_identity_bindings" {
  description = "Workload Identity bindings (K8s SA -> GCP SA)"
  value       = module.iam.workload_identity_bindings
}

output "project_id" {
  description = "GCP project ID"
  value       = var.project_id
}

output "monitoring_logging_api_enabled" {
  description = "Whether Logging/Monitoring APIs are enabled"
  value       = module.monitoring.logging_api_enabled && module.monitoring.monitoring_api_enabled
}

module "orion_worker" {
  count  = var.enable_orion_worker ? 1 : 0
  source = "../../../modules/gcp/orion_worker"

  namespace   = "orion-worker"
  image       = var.orion_worker_image
  server_ws   = var.orion_worker_server_ws

  scorpio_base_url = var.orion_worker_scorpio_base_url
  scorpio_lfs_url  = var.orion_worker_scorpio_lfs_url
  rust_log          = var.orion_worker_rust_log

  tolerations = [
    {
      key      = "dedicated"
      operator = "Equal"
      value    = "orion-build"
      effect   = "NoSchedule"
    }
  ]

  node_selector = {
    nodepool = var.orion_worker_nodepool_name
  }

  cpu_request    = var.orion_worker_cpu_request
  memory_request = var.orion_worker_memory_request
  cpu_limit      = var.orion_worker_cpu_limit
  memory_limit   = var.orion_worker_memory_limit
}
