variable "project_id" {
  type = string
}

variable "region" {
  type = string
}

variable "cluster_name" {
  type = string
}

variable "network_self_link" {
  type = string
}

variable "subnetwork_self_link" {
  type = string
}

variable "ip_range_pods_name" {
  type = string
}

variable "ip_range_services_name" {
  type = string
}

variable "enable_workload_identity" {
  type    = bool
  default = true
}

variable "workload_pool" {
  type    = string
  default = null
}

variable "release_channel" {
  type    = string
  default = "REGULAR"
}

variable "enable_private_nodes" {
  type    = bool
  default = false
}

variable "enable_private_endpoint" {
  type    = bool
  default = false
}

variable "master_ipv4_cidr_block" {
  type    = string
  default = null
}

variable "logging_service" {
  type        = string
  default     = "logging.googleapis.com/kubernetes"
  description = "Logging service for GKE cluster"
}

variable "monitoring_service" {
  type        = string
  default     = "monitoring.googleapis.com/kubernetes"
  description = "Monitoring service for GKE cluster"
}

