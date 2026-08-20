# Amazon EKS module

This module creates the Kubernetes control plane and the minimum stable compute required to bootstrap and operate platform controllers. General application capacity is intentionally delegated to Karpenter.

## Resources and behavior

The module creates:

- a customer-managed KMS key with rotation for Kubernetes Secret encryption;
- an encrypted CloudWatch control-plane log group with configured retention;
- the EKS cluster with API, audit, authenticator, controller-manager, and scheduler logs;
- private API access by default and optional CIDR-restricted public access;
- explicit EKS access entries for administrator IAM principals;
- an on-demand managed node group labeled `workload-class=system`;
- VPC CNI, CoreDNS, kube-proxy, and EKS Pod Identity Agent managed add-ons;
- a Karpenter discovery tag on the cluster security group.

The cluster disables automatic administrator access for the Terraform caller. An operator must provide at least one reviewed administrator role ARN before a real deployment or there may be no intended administrative access path.

## Inputs

| Name | Required/default | Purpose |
| --- | --- | --- |
| `cluster_name` | required | EKS name and resource-name prefix. |
| `cluster_version` | required | Kubernetes version reviewed for the environment. |
| `subnet_ids` | required | Private subnets used by the control plane and system nodes. |
| `service_ipv4_cidr` | `172.20.0.0/16` | Kubernetes Service address range; it must not overlap connected networks. |
| `endpoint_public_access` | `false` | Enables the public EKS API endpoint. |
| `public_access_cidrs` | `[]` | Allowed public endpoint source CIDRs when enabled. |
| `cluster_admin_principal_arns` | `[]` | IAM roles/users granted EKS cluster administrator policy. |
| `system_node_instance_types` | `["m6i.large"]` | Allowed managed system node instance types. |
| `system_node_min_size` | `2` | Minimum system nodes. |
| `system_node_desired_size` | `2` | Initial system nodes. |
| `system_node_max_size` | `4` | Maximum system nodes. |
| `log_retention_days` | `365` | Control-plane log retention. |
| `kms_deletion_window_days` | `30` | KMS scheduled-deletion safety window. |
| `tags` | `{}` | Additional tags. |

## Outputs

Outputs include cluster name and ARN, sensitive endpoint and certificate-authority data, cluster security-group ID, OIDC issuer, system node-role ARN, and KMS key ARN. Downstream modules use the cluster ARN/name for Karpenter and Pod Identity and the KMS key for application log encryption.

## Usage

```hcl
module "eks" {
  source = "../../modules/eks"

  cluster_name                = local.cluster_name
  cluster_version             = "1.35"
  subnet_ids                  = module.vpc.private_subnet_ids
  cluster_admin_principal_arns = ["arn:aws:iam::<AWS_ACCOUNT_ID>:role/platform-admin"]
  tags                        = local.tags
}
```

## Bootstrap and dependencies

The VPC must exist first. The managed node group gives CoreDNS, Argo CD, Karpenter, and other controllers stable on-demand capacity, preventing an autoscaler bootstrap loop. After Terraform completes, install Argo CD and let it reconcile Karpenter and workload configuration.

Because the API endpoint is private by default, Terraform operators, GitOps bootstrap clients, and incident responders need VPC connectivity through VPN, Direct Connect, a bastion, or an approved runner inside the network.

## Security and operations

- Keep public API access disabled unless a documented operational requirement exists.
- Never use `0.0.0.0/0` for production API CIDRs.
- Grant administrator access to roles rather than long-lived IAM users.
- Review Kubernetes and EKS version support before upgrades.
- Upgrade one environment at a time and verify add-on compatibility and workload disruption.
- Monitor KMS key state and CloudWatch ingestion/retention cost.

The module does not install Argo CD, Karpenter charts, ingress controllers, CSI drivers, or workload applications; those belong to GitOps.

## Validation and cleanup

Run `terraform validate` from an environment root after `terraform init -backend=false`. Before destroy, remove Kubernetes-created load balancers, persistent volumes, and Argo CD resources with finalizers. KMS key deletion is delayed by design.
