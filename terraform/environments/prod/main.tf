locals {
  cluster_name = "${var.project_name}-${var.environment}"
  tags = merge(var.tags, {
    Project     = var.project_name
    Environment = var.environment
    ManagedBy   = "terraform"
  })
}

provider "aws" {
  region = var.aws_region
  default_tags {
    tags = local.tags
  }
}

module "vpc" {
  source             = "../../modules/vpc"
  name               = local.cluster_name
  cluster_name       = local.cluster_name
  aws_region         = var.aws_region
  vpc_cidr           = var.vpc_cidr
  single_nat_gateway = var.single_nat_gateway
  tags               = local.tags
}

module "eks" {
  source                       = "../../modules/eks"
  cluster_name                 = local.cluster_name
  cluster_version              = var.cluster_version
  subnet_ids                   = module.vpc.private_subnet_ids
  endpoint_public_access       = var.endpoint_public_access
  public_access_cidrs          = var.public_access_cidrs
  cluster_admin_principal_arns = var.cluster_admin_principal_arns
  system_node_min_size         = 3
  system_node_desired_size     = 3
  system_node_max_size         = 6
  log_retention_days           = 365
  tags                         = local.tags
}

module "karpenter" {
  source       = "../../modules/karpenter"
  cluster_name = module.eks.cluster_name
  cluster_arn  = module.eks.cluster_arn
  tags         = local.tags
}

module "iam" {
  source       = "../../modules/iam"
  cluster_name = module.eks.cluster_name
  tags         = local.tags
  workloads    = {}
}

module "observability" {
  source         = "../../modules/observability"
  cluster_name   = module.eks.cluster_name
  kms_key_arn    = module.eks.kms_key_arn
  retention_days = 365
  tags           = local.tags
}

module "gpu_nodes" {
  source        = "../../modules/gpu-nodes"
  enabled       = var.enable_gpu_nodes
  cluster_name  = module.eks.cluster_name
  node_role_arn = module.karpenter.node_role_arn
  subnet_ids    = module.vpc.private_subnet_ids
  tags          = local.tags
}
