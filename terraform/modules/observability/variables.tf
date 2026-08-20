variable "cluster_name" {
  type = string
}
variable "kms_key_arn" {
  type = string
}
variable "retention_days" {
  type    = number
  default = 365
}
variable "tags" {
  type    = map(string)
  default = {}
}
