output "node_role_name" {
  value = aws_iam_role.node.name
}
output "node_role_arn" {
  value = aws_iam_role.node.arn
}
output "controller_role_arn" {
  value = aws_iam_role.controller.arn
}