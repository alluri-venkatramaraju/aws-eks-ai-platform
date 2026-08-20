output "vpc_id" {
  value = module.vpc.vpc_id
}
output "private_subnet_ids" {
  value = module.vpc.private_subnet_ids
}
output "cluster_name" {
  value = module.eks.cluster_name
}
output "cluster_endpoint" {
  value     = module.eks.cluster_endpoint
  sensitive = true
}
output "karpenter_node_role_name" {
  value = module.karpenter.node_role_name
}