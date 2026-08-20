output "node_group_name" {
  value = try(aws_eks_node_group.gpu[0].node_group_name, null)
}