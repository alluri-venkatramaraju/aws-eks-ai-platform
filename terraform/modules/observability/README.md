# AWS observability foundation module

This Terraform module creates the AWS-side destinations reserved for application and OpenTelemetry Collector logs. Kubernetes-native metrics, dashboards, and collector configuration remain under Argo CD so the AWS infrastructure and in-cluster configuration have clear ownership boundaries.

## Resources

Two CloudWatch log groups are created:

- `/aws/eks/<cluster-name>/application` for structured application logs;
- `/aws/eks/<cluster-name>/otel` for collector or exported telemetry logs.

Both use the EKS module's customer-managed KMS key and an environment-configurable retention period. Every environment currently retains these audit-oriented log groups for 365 days; operators should validate that duration against legal, security, and cost requirements.

This module reserves secure log destinations but does not install a log shipper or configure an OpenTelemetry AWS exporter. The collector currently uses debug and Prometheus exporters; connect an approved exporter before expecting data in these log groups.

## Inputs and outputs

| Name | Required/default | Purpose |
| --- | --- | --- |
| `cluster_name` | required | Namespaces the CloudWatch log groups. |
| `kms_key_arn` | required | Encrypts stored log data. |
| `retention_days` | `365` | CloudWatch retention period. |
| `tags` | `{}` | Additional resource tags. |

The module returns the ARN of each log group for IAM policies, collectors, subscriptions, or integrations.

## Usage

```hcl
module "observability" {
  source = "../../modules/observability"

  cluster_name  = module.eks.cluster_name
  kms_key_arn   = module.eks.kms_key_arn
  retention_days = 365
  tags          = local.tags
}
```

## Integrating a log pipeline

When adding a collector or Fluent Bit exporter:

1. create a dedicated Pod Identity role with only the required CloudWatch Logs actions;
2. scope it to these log-group ARNs;
3. configure structured JSON parsing and stable resource attributes;
4. redact credentials, prompts, model payloads, and regulated data;
5. set bounded queues and retries so logging failure does not block inference;
6. add alerts for rejected or dropped records.

## Cost, retention, and recovery

CloudWatch charges for ingestion, archival, queries, and exports. Retention should follow investigation and compliance requirements rather than being treated as indefinite backup. High-volume debug logging can dominate platform cost; use severity filtering and sampling intentionally.

Terraform destroys these log groups with the module. Export or retain required audit evidence before environment teardown. The EKS control-plane log group is separate and owned by the EKS module.
