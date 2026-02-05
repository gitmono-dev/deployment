variable "name" {
  type        = string
  description = "Filestore instance name"
}

variable "location" {
  type        = string
  description = "Filestore zone (e.g. us-central1-b)"
}

variable "network" {
  type        = string
  description = "VPC self link"
}

variable "tier" {
  type        = string
  default     = "STANDARD"
  description = "Filestore tier"
}

variable "capacity_gb" {
  type        = number
  default     = 1024
  description = "Capacity in GB"
}

variable "file_share_name" {
  type        = string
  default     = "share1"
  description = "File share name"
}

variable "reserved_ip_range" {
  type        = string
  default     = null
  description = "Optional reserved IP range (e.g. 10.0.20.0/29)"
}
