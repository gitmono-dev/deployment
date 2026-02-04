variable "name" {
  type        = string
  description = "Ingress name"
}

variable "namespace" {
  type        = string
  default     = "default"
  description = "Kubernetes namespace"
}

variable "static_ip_name" {
  type        = string
  default     = null
  description = "Global static IP name for GCE ingress"
}

variable "ingress_class_name" {
  type        = string
  default     = "gce"
  description = "Ingress class name"
}

variable "managed_certificate_domains" {
  type        = list(string)
  default     = []
  description = "Domains for GKE ManagedCertificate"
}

variable "rules" {
  type = list(object({
    host         = string
    service_name = string
    service_port = number
  }))
  description = "Ingress host rules"
}
