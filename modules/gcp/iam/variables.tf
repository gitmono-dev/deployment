variable "project_id" {
  type        = string
  description = "GCP project ID"
}

variable "prefix" {
  type        = string
  description = "Prefix for resource names"
  default     = "mega"
}

variable "service_accounts" {
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

