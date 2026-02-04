variable "project_id" {
  type = string
}

variable "region" {
  type = string
}

variable "cluster_name" {
  type = string
}

variable "name" {
  type = string
}

variable "machine_type" {
  type = string
}

variable "disk_size_gb" {
  type = number
}

variable "min_count" {
  type = number
}

variable "max_count" {
  type = number
}

variable "service_account" {
  type    = string
  default = null
}

variable "create_service_account" {
  type    = bool
  default = false
}

variable "service_account_id" {
  type    = string
  default = null
}

variable "tags" {
  type    = list(string)
  default = []
}

variable "enable_autoscaling" {
  type    = bool
  default = true
}

variable "labels" {
  type    = map(string)
  default = {}
}

variable "taints" {
  type = list(object({
    key    = string
    value  = string
    effect = string
  }))
  default = []
}

