variable "enabled" {
  type    = bool
  default = false
}
variable "cluster_name" {
  type = string
}
variable "node_role_arn" {
  type = string
}
variable "subnet_ids" {
  type = list(string)
}
variable "instance_types" {
  type    = list(string)
  default = ["g5.xlarge"]
}
variable "capacity_type" {
  type    = string
  default = "SPOT"
  validation {
    condition     = contains(["SPOT", "ON_DEMAND"], var.capacity_type)
    error_message = "capacity_type must be SPOT or ON_DEMAND."
  }
}
variable "max_size" {
  type    = number
  default = 2
}
variable "tags" {
  type    = map(string)
  default = {}
}