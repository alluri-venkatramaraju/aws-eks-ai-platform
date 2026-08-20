# ADR 0003: Use Argo CD

## Context

Kubernetes configuration should be auditable, repeatable, and reconciled continuously.

## Decision

Use Argo CD to manage platform components and workloads from Git.

## Alternatives

Direct CI kubectl deployment, Flux, or a hosted deployment controller.

## Consequences

Git becomes the desired-state source and drift is visible. Initial bootstrap and repository access require explicit design.
