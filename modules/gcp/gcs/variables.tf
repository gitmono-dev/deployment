variable "name" {
  type        = string
  description = "Bucket name"
}

variable "location" {
  type        = string
  description = "Bucket location"
}

variable "force_destroy" {
  type        = bool
  default     = false
  description = "Allow force deletion of bucket objects"
}

variable "uniform_bucket_level_access" {
  type        = bool
  default     = true
  description = "Enable uniform bucket-level access"
}

