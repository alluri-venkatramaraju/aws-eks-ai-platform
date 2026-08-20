# ADR 0004: Use OpenTelemetry

## Context

Inference and training workflows need portable distributed tracing.

## Decision

Instrument applications with OpenTelemetry and export through OTLP-configured collectors.

## Alternatives

Provider-specific SDKs or logs-only observability.

## Consequences

Telemetry is portable across backends, but collector sizing, sampling, and retention must be managed.
