locals {
  enable_build_env = var.enable_build_env
  enable_gcs       = var.enable_gcs
  enable_cloud_sql = var.enable_cloud_sql
  enable_redis     = var.enable_redis
  enable_apps      = var.enable_apps

  enable_private_networking = var.enable_private_networking

  # Strictly use app_name for resource naming (Convention over Configuration)
  network_name            = "${var.app_name}-vpc"
  subnet_name             = "${var.app_name}-subnet"
  gcs_bucket              = "${var.app_name}-storage"
  cloud_sql_instance_name = var.cloud_sql_instance_name != "" ? var.cloud_sql_instance_name : "${var.app_name}-db"
  redis_instance_name     = var.redis_instance_name != "" ? var.redis_instance_name : "${var.app_name}-redis"
  mono_service_name       = "${var.app_name}-backend"
  ui_service_name         = "${var.app_name}-ui"
  orion_service_name      = "${var.app_name}-orion"
  campsite_service_name   = "${var.app_name}-campsite"
  vpc_connector_name      = "${var.app_name}-cr-conn"

  enable_lb = var.enable_lb
}



# Network module
module "network" {
  count  = local.enable_private_networking ? 1 : 0
  source = "../../../modules/gcp/network"

  app_name                 = var.app_name
  region                   = var.region
  network_name             = local.network_name
  subnet_name              = local.subnet_name
  subnet_cidr              = var.subnet_cidr
  pods_secondary_range     = var.pods_secondary_range
  services_secondary_range = var.services_secondary_range
}

# IAM module
module "iam" {
  source = "../../../modules/gcp/iam"

  project_id       = var.project_id
  app_name         = coalesce(var.app_suffix, var.app_name)
  service_accounts = var.iam_service_accounts
}

# Monitoring module
module "monitoring" {
  source = "../../../modules/gcp/monitoring"

  project_id                  = var.project_id
  app_name                    = var.app_name
  enable_logging              = var.enable_logging
  enable_monitoring           = var.enable_monitoring
  enable_alerts               = var.enable_alerts
  alert_notification_channels = var.alert_notification_channels
  log_sink_name               = var.log_sink_name
  log_sink_destination        = var.log_sink_destination
}

# GCS module
module "gcs" {
  count  = local.enable_gcs ? 1 : 0
  source = "../../../modules/gcp/gcs"

  name                        = local.gcs_bucket
  location                    = var.region
  force_destroy               = var.gcs_force_destroy
  uniform_bucket_level_access = var.gcs_uniform_bucket_level_access
}

# Cloud SQL module
module "cloud_sql" {
  count  = local.enable_cloud_sql ? 1 : 0
  source = "../../../modules/gcp/cloud_sql"

  name                              = local.cloud_sql_instance_name
  database_version                  = var.cloud_sql_database_version
  region                            = var.region
  tier                              = var.cloud_sql_tier
  disk_size                         = var.cloud_sql_disk_size
  disk_type                         = var.cloud_sql_disk_type
  availability_type                 = var.cloud_sql_availability_type
  private_network                   = local.enable_private_networking ? module.network[0].network_self_link : ""
  private_ip_prefix_length          = var.cloud_sql_private_ip_prefix_length
  enable_private_service_connection = var.cloud_sql_enable_private_service_connection
  enable_public_ip                  = var.cloud_sql_enable_public_ip
  db_name                           = var.cloud_sql_db_name
  db_username                       = var.db_username
  db_password                       = var.db_password
  backup_enabled                    = var.cloud_sql_backup_enabled
  deletion_protection               = var.cloud_sql_deletion_protection
}

# Redis module
module "redis" {
  count  = local.enable_redis ? 1 : 0
  source = "../../../modules/gcp/redis"

  name                    = local.redis_instance_name
  region                  = var.region
  tier                    = var.redis_tier
  memory_size_gb          = var.redis_memory_size_gb
  network                 = local.enable_private_networking ? module.network[0].network_self_link : ""
  transit_encryption_mode = var.redis_transit_encryption_mode
}



# Serverless VPC Access Connector
module "vpc_connector" {
  count  = local.enable_private_networking ? 1 : 0
  source = "../../../modules/gcp/vpc_connector"

  name          = local.vpc_connector_name
  region        = var.region
  network       = module.network[0].network_self_link
  ip_cidr_range = var.vpc_connector_cidr
}

# Cloud Run: Backend
module "mono_cloud_run" {
  count  = local.enable_apps ? 1 : 0
  source = "../../../modules/gcp/cloud_run"

  project_id   = var.project_id
  region       = var.region
  service_name = local.mono_service_name
  image        = var.app_image
  env_vars = {
    MEGA_LOG__LEVEL                  = "info"
    MEGA_DATABASE__DB_URL            = "postgres://${var.db_username}:${var.db_password}@${local.enable_cloud_sql ? module.cloud_sql[0].db_endpoint : null}:5432/${var.cloud_sql_db_name}"
    MEGA_MONOREPO__STORAGE_TYPE      = "gcs"
    MEGA_BUILD__ORION_SERVER         = "https://orion.${var.base_domain}"
    MEGA_LFS__STORAGE_TYPE           = "gcs"
    MEGA_LFS__HTTP_URL               = "https://git.${var.base_domain}"
    MEGA_OBJECT_STORAGE__GCS__BUCKET = "${local.gcs_bucket}"
    MEGA_OAUTH__CAMPSITE_API_DOMAIN  = "https://api.${var.base_domain}"
    MEGA_OAUTH__ALLOWED_CORS_ORIGINS = "https://app.${var.base_domain}"
    MEGA_REDIS__URL                  = "redis://${local.enable_redis ? module.redis[0].host : null}:6379"
  }
  cpu            = "1"
  memory         = "1024Mi"
  min_instances  = 0
  max_instances  = 10
  allow_unauth   = true
  container_port = 8000

  vpc_connector = local.enable_private_networking ? module.vpc_connector[0].name : null
  vpc_egress    = var.cloud_run_vpc_egress
}

# Cloud Run: UI
module "ui_cloud_run" {
  count  = local.enable_apps ? 1 : 0
  source = "../../../modules/gcp/cloud_run"

  project_id   = var.project_id
  region       = var.region
  service_name = local.ui_service_name
  image        = var.ui_image
  env_vars     = var.ui_env_vars

  cpu            = "1"
  memory         = "512Mi"
  min_instances  = 0
  max_instances  = 10
  allow_unauth   = true
  container_port = 3000

  vpc_connector = local.enable_private_networking ? module.vpc_connector[0].name : null
  vpc_egress    = var.cloud_run_vpc_egress
}

# Cloud Run: Orion Server
module "orion_cloud_run" {
  count  = local.enable_apps && var.orion_image != "" ? 1 : 0
  source = "../../../modules/gcp/cloud_run"

  project_id   = var.project_id
  region       = var.region
  service_name = local.orion_service_name
  image        = var.orion_image
  env_vars = {
    # MEGA_CONFIG                     = "/opt/mega/etc/config.toml"
    MEGA_ORION_SERVER__DB_URL       = "postgres://${var.db_username}:${var.db_password}@${local.enable_cloud_sql ? module.cloud_sql[0].db_endpoint : null}:5432/${var.cloud_sql_db_name}"
    MEGA_ORION_SERVER__MONOBASE_URL = "https://git.${var.base_domain}"
    MEGA_ORION_SERVER__STORAGE_TYPE = "gcs"
  }

  cpu            = "1"
  memory         = "512Mi"
  min_instances  = 0
  max_instances  = 10
  allow_unauth   = true
  container_port = 8004

  vpc_connector = local.enable_private_networking ? module.vpc_connector[0].name : null
  vpc_egress    = var.cloud_run_vpc_egress
}

# Cloud Run: Campsite
module "campsite_cloud_run" {
  count  = local.enable_apps && var.campsite_image != "" ? 1 : 0
  source = "../../../modules/gcp/cloud_run"

  project_id   = var.project_id
  region       = var.region
  service_name = local.campsite_service_name
  image        = var.campsite_image
  env_vars = {
    DEV_APP_URL      = "https://app.${var.base_domain}"
    RAILS_ENV        = "staging-buck2hub"
    RAILS_MASTER_KEY = "${var.rails_master_key}"
    SERVER_COMMAND   = "bundle exec puma"
  }


  cpu               = "1"
  memory            = "1024Mi"
  min_instances     = 0
  max_instances     = 10
  allow_unauth      = true
  container_port    = 8080
  enable_migrations = true
  vpc_connector     = local.enable_private_networking ? module.vpc_connector[0].name : null
  vpc_egress        = var.cloud_run_vpc_egress
}

# Load Balancer module
module "lb_backends" {
  count  = var.enable_lb ? 1 : 0
  source = "../../../modules/gcp/load_balancer"

  project_id = var.project_id
  region     = var.region
  lb_name    = "${var.app_name}-lb"
  routes = {
    git = {
      host    = "git.${var.base_domain}"
      service = "${local.mono_service_name}"
    },
    app = {
      host    = "app.${var.base_domain}"
      service = "${local.ui_service_name}"
    }
    auth = {
      host    = "auth.${var.base_domain}"
      service = "${local.campsite_service_name}"
    }
    api = {
      host    = "api.${var.base_domain}"
      service = "${local.campsite_service_name}"
    }
    orion = {
      host    = "orion.${var.base_domain}"
      service = "${local.orion_service_name}"
    }

  }
  # backend_service_name = local.mono_service_name
  # ui_service_name      = local.ui_service_name
  lb_domain = var.base_domain
  # api_path_prefixes    = var.lb_api_path_prefixes
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

output "mono_cloud_run_url" {
  value = local.enable_apps ? module.mono_cloud_run[0].url : null
}

output "ui_cloud_run_url" {
  value = local.enable_apps ? module.ui_cloud_run[0].url : null
}

output "orion_cloud_run_url" {
  value = local.enable_apps && var.orion_image != "" ? module.orion_cloud_run[0].url : null
}

output "campsite_cloud_run_url" {
  value = local.enable_apps && var.campsite_image != "" ? module.campsite_cloud_run[0].url : null
}

output "project_id" {
  description = "GCP project ID"
  value       = var.project_id
}

output "monitoring_logging_api_enabled" {
  description = "Whether Logging/Monitoring APIs are enabled"
  value       = module.monitoring.logging_api_enabled && module.monitoring.monitoring_api_enabled
}

output "lb_ip" {
  description = "The public Anycast IP address of the load balancer"
  value       = var.enable_lb ? module.lb_backends[0].lb_ip : null
}
