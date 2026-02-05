variable "project_id" {
  type = string
}

variable "region" {
  type    = string
  default = "us-central1"
}

variable "zone" {
  type        = string
  description = "GCP zone for zonal resources (e.g. Filestore)."
  default     = ""
}

variable "zones" {
  type        = list(string)
  description = "Zones for the node pool. If empty, node_locations will not be set and GKE will choose."
  default     = []
}

variable "name_prefix" {
  type    = string
  default = "mega-prod"
}

variable "base_domain" {
  type    = string
  default = ""
}

variable "enable_build_env" {
  type    = bool
  default = true
}

variable "enable_gcs" {
  type    = bool
  default = true
}

variable "enable_cloud_sql" {
  type    = bool
  default = true
}

variable "enable_redis" {
  type    = bool
  default = true
}

variable "enable_filestore" {
  type    = bool
  default = true
}

variable "enable_apps" {
  type    = bool
  default = true
}

variable "enable_ingress" {
  type    = bool
  default = true
}

variable "enable_logging" {
  type    = bool
  default = true
}

variable "enable_monitoring" {
  type    = bool
  default = true
}

variable "enable_alerts" {
  type    = bool
  default = true
}

variable "alert_notification_channels" {
  type        = list(string)
  default     = []
  description = "List of notification channel IDs for alerts"
}

variable "log_sink_name" {
  type        = string
  default     = ""
  description = "Optional log sink name for exporting logs"
}

variable "log_sink_destination" {
  type        = string
  default     = ""
  description = "Optional log sink destination"
}

variable "network_name" {
  type    = string
  default = "mega-prod-net"
}

variable "subnet_name" {
  type    = string
  default = "mega-prod-subnet"
}

variable "subnet_cidr" {
  type    = string
  default = "10.40.0.0/16"
}

variable "pods_secondary_range" {
  type    = string
  default = "10.41.0.0/16"
}

variable "services_secondary_range" {
  type    = string
  default = "10.42.0.0/16"
}

variable "cluster_name" {
  type    = string
  default = "mega-prod"
}

variable "artifact_registry_location" {
  type    = string
  default = "us-central1"
}

variable "artifact_registry_repo" {
  type    = string
  default = "orion-worker-prod"
}

variable "nodepool_name" {
  type    = string
  default = "prod-default"
}

variable "node_machine_type" {
  type    = string
  default = "e2-standard-8"
}

variable "node_disk_size_gb" {
  type    = number
  default = 200
}

variable "node_min_count" {
  type    = number
  default = 2
}

variable "node_max_count" {
  type    = number
  default = 20
}

variable "gcs_bucket" {
  type        = string
  description = "GCS bucket name"
  default     = ""
}

variable "gcs_force_destroy" {
  type        = bool
  description = "Allow force deletion of bucket objects"
  default     = false
}

variable "gcs_uniform_bucket_level_access" {
  type        = bool
  description = "Enable uniform bucket-level access"
  default     = true
}

variable "cloud_sql_instance_name" {
  type        = string
  description = "Cloud SQL instance name"
  default     = ""
}

variable "cloud_sql_database_version" {
  type        = string
  description = "Cloud SQL database version (e.g. POSTGRES_17, MYSQL_8_0)"
  default     = "POSTGRES_17"
}

variable "cloud_sql_tier" {
  type        = string
  description = "Cloud SQL instance tier"
  default     = "db-g1-small"
}

variable "cloud_sql_disk_size" {
  type        = number
  description = "Cloud SQL disk size in GB"
  default     = 100
}

variable "cloud_sql_disk_type" {
  type        = string
  description = "Cloud SQL disk type"
  default     = "PD_SSD"
}

variable "cloud_sql_availability_type" {
  type        = string
  description = "Cloud SQL availability type (ZONAL or REGIONAL)"
  default     = "REGIONAL"
}

variable "cloud_sql_private_ip_prefix_length" {
  type        = number
  description = "Prefix length for private services range"
  default     = 16
}

variable "cloud_sql_enable_private_service_connection" {
  type        = bool
  description = "Create private service networking connection"
  default     = true
}

variable "cloud_sql_enable_public_ip" {
  type        = bool
  description = "Enable public IPv4 for Cloud SQL"
  default     = false
}

variable "cloud_sql_db_name" {
  type        = string
  description = "Default database name"
  default     = ""
}

variable "cloud_sql_backup_enabled" {
  type        = bool
  description = "Enable automated backups"
  default     = true
}

variable "cloud_sql_deletion_protection" {
  type        = bool
  description = "Enable deletion protection"
  default     = true
}

variable "redis_instance_name" {
  type        = string
  description = "Memorystore instance name"
  default     = ""
}

variable "redis_tier" {
  type        = string
  description = "Memorystore tier"
  default     = "STANDARD_HA"
}

variable "redis_memory_size_gb" {
  type        = number
  description = "Memory size in GB"
  default     = 4
}

variable "redis_transit_encryption_mode" {
  type        = string
  description = "Transit encryption mode"
  default     = "DISABLED"
}

variable "filestore_instance_name" {
  type        = string
  description = "Filestore instance name"
  default     = ""
}

variable "filestore_tier" {
  type        = string
  description = "Filestore tier"
  default     = "STANDARD"
}

variable "filestore_capacity_gb" {
  type        = number
  description = "Capacity in GB"
  default     = 1024
}

variable "filestore_file_share_name" {
  type        = string
  description = "File share name"
  default     = "share1"
}

variable "filestore_reserved_ip_range" {
  type        = string
  description = "Optional reserved IP range (e.g. 10.0.20.0/29)"
  default     = null
}

variable "app_service_name" {
  type        = string
  description = "Kubernetes service name"
  default     = ""
}

variable "app_namespace" {
  type        = string
  description = "Kubernetes namespace"
  default     = "default"
}

variable "app_image" {
  type        = string
  description = "Container image"
  default     = ""
}

variable "app_container_port" {
  type        = number
  description = "Container port"
  default     = 80
}

variable "app_env" {
  type = list(map(string))
  description = "Environment variables"
  default     = []
}

variable "app_volumes" {
  type = list(object({
    name       = string
    nfs_server = string
    nfs_path   = string
  }))
  description = "Pod volumes (NFS only)"
  default     = []
}

variable "app_volume_mounts" {
  type = list(object({
    name       = string
    mount_path = string
    read_only  = bool
  }))
  description = "Container volume mounts"
  default     = []
}

variable "app_replicas" {
  type        = number
  description = "Number of replicas"
  default     = 3
}

variable "app_service_type" {
  type        = string
  description = "Kubernetes service type"
  default     = "ClusterIP"
}

variable "app_cpu_request" {
  type        = string
  description = "CPU request"
  default     = null
}

variable "app_memory_request" {
  type        = string
  description = "Memory request"
  default     = null
}

variable "app_cpu_limit" {
  type        = string
  description = "CPU limit"
  default     = null
}

variable "app_memory_limit" {
  type        = string
  description = "Memory limit"
  default     = null
}

variable "app_enable_hpa" {
  type        = bool
  description = "Enable HorizontalPodAutoscaler"
  default     = true
}

variable "app_hpa_min_replicas" {
  type        = number
  description = "HPA minimum replicas"
  default     = 3
}

variable "app_hpa_max_replicas" {
  type        = number
  description = "HPA maximum replicas"
  default     = 20
}

variable "app_hpa_cpu_utilization" {
  type        = number
  description = "Target CPU utilization percentage"
  default     = 70
}

variable "ingress_name" {
  type        = string
  description = "Ingress name"
  default     = ""
}

variable "ingress_namespace" {
  type        = string
  description = "Kubernetes namespace"
  default     = "default"
}

variable "ingress_static_ip_name" {
  type        = string
  description = "Global static IP name for GCE ingress"
  default     = null
}

variable "ingress_class_name" {
  type        = string
  description = "Ingress class name"
  default     = "gce"
}

variable "ingress_managed_certificate_domains" {
  type        = list(string)
  description = "Domains for GKE ManagedCertificate"
  default     = []
}

variable "ingress_rules" {
  type = list(object({
    host         = string
    service_name = string
    service_port = number
  }))
  description = "Ingress host rules"
  default     = []
}

variable "storage_key" {
  type        = string
  description = "Storage access key (mapped from AWS s3_key)"
  default     = ""
  sensitive   = true
}

variable "storage_secret_key" {
  type        = string
  description = "Storage secret key (mapped from AWS s3_secret_key)"
  default     = ""
  sensitive   = true
}

variable "storage_bucket" {
  type        = string
  description = "Storage bucket name (mapped from AWS s3_bucket)"
  default     = ""
}

variable "db_username" {
  type        = string
  description = "Database username"
  default     = ""
  sensitive   = true
}

variable "db_password" {
  type        = string
  description = "Database password"
  default     = ""
  sensitive   = true
}

variable "db_schema" {
  type        = string
  description = "Database schema name (compat with AWS envs/dev)"
  default     = ""
}

variable "rails_master_key" {
  type        = string
  description = "Rails master key (compat with AWS envs/dev)"
  default     = ""
  sensitive   = true
}

variable "rails_env" {
  type        = string
  description = "Rails env (compat with AWS envs/dev)"
  default     = ""
}

variable "ui_env" {
  type        = string
  description = "UI env (compat with AWS envs/dev)"
  default     = ""
}

variable "app_suffix" {
  type        = string
  description = "Application suffix (compat with AWS envs/dev)"
  default     = ""
}

variable "iam_service_accounts" {
  type = map(object({
    display_name = optional(string)
    description  = optional(string)
    roles        = optional(list(string), [])
    wi_bindings  = optional(list(object({
      namespace                 = string
      k8s_service_account_name  = string
    })), [])
  }))
  description = "Service accounts to create and their IAM roles / Workload Identity bindings"
  default     = {}
}

variable "enable_orion_worker" {
  type        = bool
  default     = false
  description = "Enable Orion Worker deployment"
}

variable "orion_worker_image" {
  type        = string
  default     = "public.ecr.aws/m8q5m4u3/mega:orion-client-0.1.0-pre-release-amd64"
  description = "Orion Worker container image"
}

variable "orion_worker_server_ws" {
  type        = string
  default     = "wss://orion.gitmono.com/ws"
  description = "Orion server WebSocket URL"
}

variable "orion_worker_scorpio_base_url" {
  type        = string
  default     = "https://git.gitmono.com"
  description = "Scorpio base URL"
}

variable "orion_worker_scorpio_lfs_url" {
  type        = string
  default     = "https://git.gitmono.com"
  description = "Scorpio LFS URL"
}

variable "orion_worker_rust_log" {
  type        = string
  default     = "info"
  description = "Rust log level"
}

variable "orion_worker_nodepool_name" {
  type        = string
  default     = "prod-default"
  description = "Node pool name for Orion Worker scheduling"
}

variable "orion_worker_cpu_request" {
  type        = string
  default     = "6"
  description = "CPU request for Orion Worker"
}

variable "orion_worker_memory_request" {
  type        = string
  default     = "24Gi"
  description = "Memory request for Orion Worker"
}

variable "orion_worker_cpu_limit" {
  type        = string
  default     = "8"
  description = "CPU limit for Orion Worker"
}

variable "orion_worker_memory_limit" {
  type        = string
  default     = "30Gi"
  description = "Memory limit for Orion Worker"
}
