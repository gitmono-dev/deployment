variable "name" {
  type        = string
  description = "Memorystore instance name"
}

variable "region" {
  type        = string
  description = "GCP region"
}

variable "tier" {
  type        = string
  default     = "STANDARD_HA"
  description = "Memorystore tier"
}

variable "memory_size_gb" {
  type        = number
  default     = 1
  description = "Memory size in GB"
}

variable "network" {
  type        = string
  description = "VPC self link"
}

variable "transit_encryption_mode" {
  type        = string
  default     = "DISABLED"
  description = "Transit encryption mode"
}

