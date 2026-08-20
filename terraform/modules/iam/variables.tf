variable "cluster_name" {
  type = string
}
variable "workloads" {
  type = map(object({ namespace = string, service_account = string, policy_statements = list(object({ Effect = string, Action = list(string), Resource = list(string)
    }))
  }))
  default = {}
}
variable "tags" {
  type    = map(string)
  default = {}
}