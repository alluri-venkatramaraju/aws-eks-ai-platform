variable "name" {
  type = string
}
variable "cluster_name" {
  type = string
}
variable "aws_region" {
  type = string
}
variable "vpc_cidr" {
  type = string
}
variable "availability_zones" {
  type    = list(string)
  default = []
}
variable "az_count" {
  type    = number
  default = 3
}
variable "enable_nat_gateway" {
  type    = bool
  default = true
}
variable "single_nat_gateway" {
  type    = bool
  default = true
}
variable "enable_vpc_endpoints" {
  type    = bool
  default = true
}
variable "interface_endpoint_services" {
  type    = list(string)
  default = ["ecr.api", "ecr.dkr", "ec2", "logs", "sts", "secretsmanager"]
}
variable "tags" {
  type    = map(string)
  default = {}
}