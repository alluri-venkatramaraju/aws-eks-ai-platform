# OpenTelemetry collection

This directory defines the platform telemetry gateway used by workloads. The OpenTelemetry Operator is installed by Argo CD, and the `OpenTelemetryCollector` custom resource creates a two-replica collector deployment in the `ai-platform` namespace.

## Current data flow

```text
model server or training job
        |
        | OTLP/gRPC :4317 or OTLP/HTTP :4318
        v
OpenTelemetry Collector
        |
        +-- traces -> debug exporter
        +-- metrics -> Prometheus exporter :8889
```

The collector uses a memory limiter to protect the pod and a batch processor to reduce exporter overhead. Resource requests and limits prevent an unbounded telemetry workload from consuming an entire node.

The debug trace exporter is deliberately a reference default, not durable production storage. Select and configure an approved backend such as AWS X-Ray, Amazon Managed Service for Prometheus, a managed OTLP service, or a self-hosted tracing backend before production use.

## Workload configuration

Applications send telemetry to the collector service with environment variables similar to:

```text
OTEL_SERVICE_NAME=model-server
OTEL_EXPORTER_OTLP_ENDPOINT=http://otel-collector.ai-platform.svc:4317
```

Every service should attach environment, service version, namespace, and workload identity as resource attributes. Never include prompts, credentials, model inputs, or customer data in span attributes without an explicit data-governance decision.

## Production considerations

- Add tail or probabilistic sampling appropriate to traffic and investigation requirements.
- Use queued retry and persistent storage when the selected exporter supports it.
- Define TLS and authentication for telemetry leaving the cluster.
- Set environment-specific retention and ingestion budgets at the backend.
- Add health checks, collector self-observability, alerts, and disruption controls.
- Use a DaemonSet collector only when node-local log or host telemetry collection justifies it.

Telemetry failure must not make inference unavailable. SDK export should remain asynchronous and bounded.

## Validation and troubleshooting

```bash
kubectl kustomize kubernetes/platform/otel
kubectl -n ai-platform get opentelemetrycollector otel
kubectl -n ai-platform get pods -l app.kubernetes.io/managed-by=opentelemetry-operator
kubectl -n ai-platform logs -l app.kubernetes.io/component=opentelemetry-collector
```

Connection errors commonly mean the operator or collector is not ready, the generated Service name differs from the workload endpoint, or NetworkPolicy does not allow port 4317/4318. Dropped telemetry usually indicates memory limits, exporter errors, or unavailable downstream storage.
