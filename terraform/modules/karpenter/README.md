# Karpenter AWS integration module

This module creates the AWS identities required by the Karpenter controller and by EC2 instances that Karpenter launches. It does not install the controller or define capacity policy; those responsibilities remain in GitOps.

## Resources

- EC2 node IAM role trusted by `ec2.amazonaws.com`;
- managed policy attachments for EKS worker operation, ECR image pulls, VPC CNI, and Systems Manager;
- EKS `EC2_LINUX` access entry for the Karpenter node role;
- controller IAM role trusted by EKS Pod Identity;
- controller policy for EC2 provisioning, instance discovery, pricing, SSM AMI lookup, passing the node role, and describing the cluster;
- Pod Identity association for service account `karpenter` in namespace `karpenter`.

## Ownership flow

```text
Terraform module
  -> controller role + Pod Identity
  -> node role + EKS access entry

Argo CD Helm Application
  -> Karpenter controller

GitOps manifests
  -> EC2NodeClass references node role and discovery tags
  -> NodePools describe CPU, spot, and optional GPU policy
```

The names in all three layers must agree. Environment overlays patch the EC2NodeClass role and discovery tag from dev to stage or prod.

## Inputs and outputs

| Name | Required/default | Purpose |
| --- | --- | --- |
| `cluster_name` | required | Target cluster and IAM role prefix. |
| `cluster_arn` | required | Resource allowed for `eks:DescribeCluster`. |
| `tags` | `{}` | Additional IAM role tags. |

Outputs expose the node role name and ARN and controller role ARN. The EC2NodeClass uses the node role name; the optional GPU managed-node module uses the ARN.

## Usage

```hcl
module "karpenter" {
  source = "../../modules/karpenter"

  cluster_name = module.eks.cluster_name
  cluster_arn  = module.eks.cluster_arn
  tags         = local.tags
}
```

## Security and production hardening

EC2 provisioning requires several APIs that cannot be completely resource-scoped. Add IAM conditions for cluster discovery tags, region, requested instance profiles, and allowed launch templates before production. Review the Systems Manager attachment if interactive node access is not part of the operating model.

Production Karpenter deployments should also configure interruption handling with SQS/EventBridge, define total CPU/memory/GPU limits, restrict instance families and generations, and monitor provisioning and disruption events.

## Troubleshooting

- Unschedulable controller: ensure the system managed node group exists and the Helm service-account name is `karpenter`.
- Controller has no AWS credentials: inspect the Pod Identity association and agent add-on.
- Nodes launch but do not join: verify the EKS access entry, node role policies, cluster endpoint reachability, and security groups.
- No subnets or security groups found: discovery tag values must equal the environment cluster name.
- `iam:PassRole` denied: the EC2NodeClass must reference the node role created by this module.

Do not delete the node role while Karpenter-created instances still exist. Drain and terminate dynamic nodes before destroying the module.
