# Optional managed GPU node group

This module provides a conservative managed-node-group fallback for GPU workloads. It is separate from Karpenter so operators can choose a managed EKS capacity path for compatibility or recovery without enabling expensive accelerated instances by default.

## Safety defaults

- `enabled` defaults to `false`.
- Minimum and desired capacity are hardcoded to zero.
- The default maximum is two nodes.
- Capacity defaults to Spot.
- Nodes are labeled `workload-class=gpu`.
- Nodes are tainted `nvidia.com/gpu=true:NoSchedule` so ordinary pods cannot consume them.

Enabling the module creates the node-group control-plane resource, but no GPU instance should run until desired capacity changes or the node group is otherwise scaled. Review AWS pricing and quotas before changing that behavior.

## Inputs and output

| Name | Required/default | Purpose |
| --- | --- | --- |
| `enabled` | `false` | Creates the managed node group. |
| `cluster_name` | required | Target EKS cluster. |
| `node_role_arn` | required | IAM role used by GPU EC2 nodes. |
| `subnet_ids` | required | Private subnets for nodes. |
| `instance_types` | `["g5.xlarge"]` | Reviewed GPU instance choices. |
| `capacity_type` | `SPOT` | `SPOT` or `ON_DEMAND`. |
| `max_size` | `2` | Maximum managed GPU nodes. |
| `tags` | `{}` | Additional tags. |

`node_group_name` is `null` when disabled and returns the created group name when enabled.

## Usage

```hcl
module "gpu_nodes" {
  source = "../../modules/gpu-nodes"

  enabled       = false
  cluster_name  = module.eks.cluster_name
  node_role_arn = module.karpenter.node_role_arn
  subnet_ids    = module.vpc.private_subnet_ids
  tags          = local.tags
}
```

GPU pods must request `nvidia.com/gpu`, select `workload-class: gpu`, and tolerate the GPU taint. See `kubernetes/workloads/batch-training/gpu-job.example.yaml` for an opt-in example.

## Karpenter versus this module

Prefer the GitOps-managed GPU Karpenter NodePool for elastic scale-from-zero, instance diversification, consolidation, and workload-driven provisioning. Use this managed group when an organization requires managed node groups, needs a controlled fallback, or has a GPU software stack validated specifically against the EKS GPU AMI path.

Do not enable both mechanisms without capacity limits and a clear scheduling preference; otherwise both may respond to the same pending pod.

## Operational considerations

- Confirm GPU instance quota and regional availability.
- Install and validate NVIDIA device support before scheduling workloads.
- Spot GPU capacity can be scarce and interruption-prone; checkpoint training data.
- Encrypt and size node volumes for model artifacts and container layers.
- Monitor idle GPU time, scheduling latency, and cost per training/inference unit.
- Drain GPU workloads and persist checkpoints before node-group upgrades or destroy.

The module uses the EKS-optimized Amazon Linux 2023 NVIDIA AMI type. Review EKS, NVIDIA driver, CUDA, and workload-framework compatibility before every cluster or AMI upgrade.
