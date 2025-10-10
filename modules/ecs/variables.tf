variable "cluster_name" {}
variable "task_family" {}
variable "environment" {}
variable "mount_points" {
  type    = list(any)
  default = []
}
variable "efs_volume" {
  type    = map(string)
  default = null
}
variable "container_name" {}
variable "container_image" {}
variable "container_port" {}
variable "service_name" {}
variable "desired_count" { default = 1 }
variable "cpu" {}
variable "memory" {}
variable "subnet_ids" {
  description = "List of subnet IDs for ECS service"
  type        = list(string)
}
variable "security_group_ids" { type = list(string) }
