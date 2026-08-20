# Prometheus monitoring

This directory connects platform workloads to the Prometheus instance installed by kube-prometheus-stack. Argo CD owns the Helm release; the manifests here define workload-specific discovery and, over time, should contain recording and alerting rules owned by this project.

## Model-server discovery

`model-server-monitor.yaml` defines a `ServiceMonitor` in `ai-platform`. It selects the `model-server` Service in the `model-serving` namespace and scrapes the named `http` port at `/metrics` every 30 seconds with a 10-second timeout.

The label chain must remain consistent:

```text
ServiceMonitor selector
  -> Service label app.kubernetes.io/name=model-server
  -> Service targetPort http
  -> container port http:8080
  -> GET /metrics
```

The application currently exports request count, error count, and cumulative latency. Add histogram buckets and model-specific success/error metrics before using the example for production service-level objectives.

## Retention and sizing

The Argo CD Helm values currently set Prometheus retention to 15 days. Retention is not a backup. Choose storage class, persistent volume size, replica strategy, and remote-write destination from the expected series count, scrape interval, availability target, and recovery objective.

Control cardinality at instrumentation time. Do not label metrics with request IDs, full paths containing user data, prompts, model output, or arbitrary exception text.

## Alerting recommendations

Useful production alerts include:

- model-server unavailable replicas;
- sustained inference error ratio;
- latency objective burn rate;
- pod restart or OOM rate;
- Karpenter provisioning failures;
- pending GPU workloads;
- collector dropped telemetry;
- Prometheus storage exhaustion and rule-evaluation failure.

Route Alertmanager receivers through External Secrets and test notification delivery. Avoid committing receiver tokens or webhook URLs.

## Validation and troubleshooting

```bash
kubectl kustomize kubernetes/platform/prometheus
kubectl -n ai-platform get servicemonitor model-server
kubectl -n model-serving get service model-server --show-labels
kubectl -n model-serving port-forward service/model-server 8080:80
curl http://127.0.0.1:8080/metrics
```

If the target is absent, verify that the Prometheus custom-resource selector admits the `ai-platform` ServiceMonitor and that its namespace selector admits `model-serving`. If the target is down, check NetworkPolicy, endpoints, probes, and the named Service port.
