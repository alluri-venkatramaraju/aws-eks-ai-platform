# ADR 0002: Use Karpenter

## Context

AI workloads vary between CPU, memory, spot, and GPU capacity.

## Decision

Use Karpenter NodePools and NodeClasses to provision nodes from pod scheduling requirements.

## Alternatives

Managed node groups only, Cluster Autoscaler, or a custom provisioning service.

## Consequences

Karpenter improves right-sizing and workload-class separation, while requiring careful disruption, limits, and IAM controls.
