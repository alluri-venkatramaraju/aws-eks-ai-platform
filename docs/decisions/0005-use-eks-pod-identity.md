# ADR 0005: Use EKS Pod Identity

## Context

Platform controllers and workloads need AWS API access without static credentials or node-wide permissions.

## Decision

Use EKS Pod Identity associations between dedicated Kubernetes service accounts and narrowly scoped IAM roles. Install the Pod Identity Agent as an EKS managed add-on.

## Alternatives

IAM Roles for Service Accounts, node instance-role permissions, or static access keys.

## Consequences

Identity configuration stays explicit in Terraform and credentials remain short-lived. The design depends on an EKS-specific agent and requires every AWS-enabled workload to use a dedicated service account and policy.
