# ADR 0001: Use Amazon EKS

## Context

The platform needs managed Kubernetes control-plane operations and native AWS integration.

## Decision

Use Amazon EKS with private worker nodes and Terraform-managed cluster infrastructure.

## Alternatives

Self-managed Kubernetes, ECS, and another managed Kubernetes service.

## Consequences

EKS reduces control-plane toil and integrates with IAM, VPC, CloudWatch, and AWS load balancing. It introduces AWS-specific cost and operational knowledge requirements.
