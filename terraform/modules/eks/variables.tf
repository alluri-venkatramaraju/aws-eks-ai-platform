variable "cluster_name" {
  type = string
}
variable "cluster_version" {
  type = string
}
variable "subnet_ids" {
  type = list(string)
}
variable "service_ipv4_cidr" {
  type    = string
  default = "172.20.0.0/16"
}
variable "endpoint_public_access" {
  type    = bool
  default = false
}
variable "public_access_cidrs" {
  type    = list(string)
  default = []
}
variable "cluster_admin_principal_arns" {
  type    = list(string)
  default = []
}
variable "system_node_instance_types" {
  type    = list(string)
  default = ["m6i.large"]
}
variable "system_node_min_size" {
  type    = number
  default = 2
}
variable "system_node_desired_size" {
  type    = number
  default = 2
}
variable "system_node_max_size" {
  type    = number
  default = 4
}
variable "log_retention_days" {
  type    = number
  default = 365
}
variable "kms_deletion_window_days" {
  type    = number
  default = 30
}
variable "tags" {
  type    = map(string)
  default = {}
}
