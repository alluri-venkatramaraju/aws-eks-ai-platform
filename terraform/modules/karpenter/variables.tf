variable "cluster_name" {
  type = string
}
variable "cluster_arn" {
  type = string
}
variable "tags" {
  type    = map(string)
  default = {}
}