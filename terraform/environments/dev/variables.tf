variable "aws_region" {
  type    = string
  default = "us-east-1"
}
variable "project_name" {
  type    = string
  default = "eks-ai-platform"
}
variable "environment" {
  type    = string
  default = "dev"
}
variable "vpc_cidr" {
  type    = string
  default = "10.42.0.0/16"
}
variable "cluster_version" {
  type    = string
  default = "1.35"
}
variable "cluster_admin_principal_arns" {
  type    = list(string)
  default = []
}
variable "endpoint_public_access" {
  type    = bool
  default = false
}
variable "public_access_cidrs" {
  type    = list(string)
  default = []
}
variable "single_nat_gateway" {
  type    = bool
  default = true
}
variable "enable_gpu_nodes" {
  type    = bool
  default = false
}
variable "tags" {
  type    = map(string)
  default = {}
}
