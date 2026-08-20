# Grafana dashboards

This directory contains dashboards owned by the AI platform. Grafana itself is installed as part of kube-prometheus-stack by the Argo CD application; this directory adds repository-managed visualization content.

## Current dashboard

`dashboard.yaml` defines a ConfigMap labeled `grafana_dashboard: "1"`. The Grafana dashboard sidecar discovers that ConfigMap and loads the embedded `model-server.json` dashboard. Its request-rate panel evaluates:

```promql
rate(model_requests_total[5m])
```

The metric originates at the model server's `/metrics` endpoint, is discovered through the `ServiceMonitor` in `kubernetes/platform/prometheus`, and is stored by Prometheus.

## Adding or changing dashboards

Keep dashboards declarative and reviewable:

1. design the panel in a non-production Grafana instance;
2. export the dashboard JSON;
3. remove instance-specific data-source UIDs and sensitive values;
4. store it in a labeled ConfigMap in this directory;
5. add the file to `kustomization.yaml`;
6. validate every PromQL expression against the metrics exposed by the workload.

Prefer stable labels such as service, environment, namespace, model, and response status. Avoid unbounded labels such as raw prompts, user IDs, request IDs, or full model outputs because they create high cardinality and may expose sensitive data.

## Credentials and access

Do not place the Grafana administrator password, OAuth client secrets, data-source credentials, or alerting credentials in Git. Source them through External Secrets. Production access should use SSO, least-privilege teams, audit logging, and a private ingress with TLS.

The Helm chart may generate a bootstrap administrator Secret if no external credential is supplied. Replace that bootstrap mechanism before treating the installation as production-ready.

## Validation and troubleshooting

```bash
kubectl kustomize kubernetes/platform/grafana
kubectl -n ai-platform get configmap model-server-dashboard
kubectl -n monitoring get pods -l app.kubernetes.io/name=grafana
```

If the dashboard is not loaded, confirm the sidecar is enabled, its label selector matches `grafana_dashboard: "1"`, and it is configured to watch the `ai-platform` namespace. If a panel is empty, query Prometheus directly and verify the `ServiceMonitor`, Service labels, and model-server metric name.
