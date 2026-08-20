output "role_arns" {
  value = { for key, role in aws_iam_role.workload : key => role.arn
  }
}