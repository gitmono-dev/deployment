variable "name" {
  type        = string
  description = "Service name"
}

variable "namespace" {
  type        = string
  default     = "default"
  description = "Kubernetes namespace"
}

variable "image" {
  type        = string
  description = "Container image"
}

variable "container_port" {
  type        = number
  description = "Container port"
}

variable "env" {
  type        = list(map(string))
  default     = []
  description = "Environment variables"
}

variable "volumes" {
  type = list(object({
    name       = string
    nfs_server = string
    nfs_path   = string
  }))
  default     = []
  description = "Pod volumes (NFS only)"
}

variable "volume_mounts" {
  type = list(object({
    name       = string
    mount_path = string
    read_only  = bool
  }))
  default     = []
  description = "Container volume mounts"
}

variable "replicas" {
  type        = number
  default     = 1
  description = "Number of replicas"
}

variable "service_type" {
  type        = string
  default     = "ClusterIP"
  description = "Kubernetes service type"
}

variable "cpu_request" {
  type        = string
  default     = null
  description = "CPU request"
}

variable "memory_request" {
  type        = string
  default     = null
  description = "Memory request"
}

variable "cpu_limit" {
  type        = string
  default     = null
  description = "CPU limit"
}

variable "memory_limit" {
  type        = string
  default     = null
  description = "Memory limit"
}

variable "enable_hpa" {
  type        = bool
  default     = false
  description = "Enable HorizontalPodAutoscaler"
}

variable "hpa_min_replicas" {
  type        = number
  default     = 1
  description = "HPA minimum replicas"
}

variable "hpa_max_replicas" {
  type        = number
  default     = 5
  description = "HPA maximum replicas"
}

variable "hpa_cpu_utilization" {
  type        = number
  default     = 80
  description = "Target CPU utilization percentage"
}

variable "service_account_name" {
  type        = string
  default     = "default"
  description = "Kubernetes service account name to use for the pod"
}
