resource "aws_eks_node_group" "gpu" {
  count           = var.enabled ? 1 : 0
  cluster_name    = var.cluster_name
  node_group_name = "gpu-fallback"
  node_role_arn   = var.node_role_arn
  subnet_ids      = var.subnet_ids
  instance_types  = var.instance_types
  ami_type        = "AL2023_x86_64_NVIDIA"
  capacity_type   = var.capacity_type
  scaling_config {
    min_size     = 0
    desired_size = 0
    max_size     = var.max_size
  }
  labels = { "workload-class" = "gpu"
  }
  taint {
    key    = "nvidia.com/gpu"
    value  = "true"
    effect = "NO_SCHEDULE"
  }
  tags = var.tags
}
