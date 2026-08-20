# VPC module

This module creates the network boundary for one EKS environment. It provides public subnets for internet-facing load balancers and NAT gateways, private subnets for EKS nodes, per-tier route tables, and optional VPC endpoints for AWS APIs used during image pulls and platform operation.

## Architecture

```text
Internet
   |
Internet Gateway
   |
Public subnet in each AZ ---- NAT gateway(s)
                                  |
Private subnet in each AZ -------+---- EKS and Karpenter nodes
   |
S3 gateway endpoint and private interface endpoints
```

Public subnets have `map_public_ip_on_launch = false`; resources receive public addressing only through an explicitly configured service such as a load balancer. Worker nodes are placed in private subnets and are tagged for internal load balancers and Karpenter discovery.

## Resources

- one DNS-enabled VPC;
- public and private subnet in each selected Availability Zone;
- internet gateway and public route table;
- private route table per Availability Zone;
- either one shared NAT gateway or one NAT gateway per Availability Zone;
- S3 gateway endpoint when endpoints are enabled;
- interface endpoints and a VPC-scoped HTTPS security group.
- a default security group with no ingress or egress rules;
- encrypted VPC flow logs retained in CloudWatch Logs for 365 days.

The default interface endpoints cover ECR API, ECR Docker registry, EC2, CloudWatch Logs, STS, and Secrets Manager.

## Inputs

| Name | Required/default | Purpose |
| --- | --- | --- |
| `name` | required | Prefix for resource names. |
| `cluster_name` | required | Value used for Karpenter subnet discovery tags. |
| `aws_region` | required | Region used to construct endpoint service names. |
| `vpc_cidr` | required | Address range divided into public and private subnet CIDRs. |
| `availability_zones` | `[]` | Explicit zones; when empty, the module selects available zones. |
| `az_count` | `3` | Number of automatically selected zones. |
| `enable_nat_gateway` | `true` | Adds outbound internet routes through NAT. |
| `single_nat_gateway` | `true` | Shares one NAT gateway to reduce non-production cost. |
| `enable_vpc_endpoints` | `true` | Enables S3 and interface endpoints. |
| `interface_endpoint_services` | AWS platform services | Interface endpoint service suffixes. |
| `tags` | `{}` | Additional resource tags. |

## Outputs

The module exports the VPC ID and CIDR, public and private subnet IDs, private route-table IDs, and flow-log group ARN. The EKS environment passes the private subnets to the EKS, Karpenter, and optional GPU modules.

## Usage

```hcl
module "vpc" {
  source = "../../modules/vpc"

  name               = "eks-ai-platform-dev"
  cluster_name       = "eks-ai-platform-dev"
  aws_region         = "us-east-1"
  vpc_cidr           = "10.42.0.0/16"
  single_nat_gateway = true
  tags               = local.tags
}
```

## Availability, cost, and security

One NAT gateway is cheaper but makes private-subnet internet egress dependent on a single AZ. Production defaults to one NAT gateway per AZ. Interface endpoints add hourly charges but keep AWS API traffic on the AWS network and can reduce NAT data processing. Review the cost against traffic volume.

Security groups on interface endpoints accept HTTPS only from the VPC CIDR. The VPC's default security group is deliberately empty, while flow logs are encrypted by a dedicated KMS key for network-audit evidence. Add endpoint policies when workloads must be restricted to particular buckets, repositories, or secrets. This module does not create workload ingress, DNS zones, transit routing, or cross-account connectivity.

## Validation and cleanup

Run `terraform fmt -check -recursive terraform` and `terraform validate` from every affected environment root. Destroy the EKS cluster and Kubernetes-created load balancers before destroying the VPC; ENIs left by load balancers or endpoints can prevent subnet and VPC deletion.
