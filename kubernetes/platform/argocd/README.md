# Argo CD GitOps bootstrap

This directory defines the handoff between Terraform-managed AWS infrastructure and Git-managed Kubernetes state. Terraform creates EKS and the identities required by platform controllers; after Argo CD is installed, the resources here make Argo CD responsible for continuously reconciling platform services and workloads.

## What is defined

`applications.yaml` contains:

- an `ai-platform` AppProject that limits approved source repositories and the destination cluster;
- `platform-config`, which reconciles an environment overlay under `gitops/`;
- External Secrets Operator for AWS Secrets Manager integration;
- Karpenter for workload-driven EC2 provisioning;
- kube-prometheus-stack for Prometheus, Alertmanager, and Grafana;
- OpenTelemetry Operator for collector lifecycle management.

The Applications use automated sync, pruning, and self-healing. A resource removed from Git can therefore be removed from the cluster. Every change should be reviewed before merge.

## Bootstrap sequence

1. Provision EKS and the supporting IAM roles with Terraform.
2. Obtain private network access to the cluster and configure `kubectl`.
3. Install Argo CD from a reviewed and pinned upstream release or Helm chart.
4. Confirm the configured GitHub repository URL is correct and accessible from Argo CD.
5. Change `gitops/dev` and `eks-ai-platform-dev` when bootstrapping stage or prod.
6. Review and update the pinned chart versions.
7. Apply the bootstrap definitions once:

   ```bash
   kubectl apply -f kubernetes/platform/argocd/applications.yaml
   ```

After bootstrap, change Kubernetes desired state through Git rather than manually applying the rendered resources.

## Dependencies and ordering

The platform configuration contains custom resources supplied by Karpenter, External Secrets, Prometheus Operator, and OpenTelemetry Operator. On first reconciliation, their CRDs and controllers must become ready before dependent resources can succeed. Argo CD will retry failed reconciliation; production deployments should add sync waves or split root applications further if deterministic ordering is required.

Karpenter also requires the Terraform-created controller Pod Identity, EC2 node role, EKS access entry, discovery tags, and managed system capacity. External Secrets requires a dedicated AWS identity before any `ExternalSecret` should be introduced.

## Security

The example AppProject currently permits all cluster resource kinds and all namespaces because the platform installs CRDs and cluster-scoped controllers. For a production tenant model, split platform administration from workload projects and narrow destinations and resource allowlists. Use a read-only deploy key or GitHub App for private repository access and store its credential in a secret manager.

Do not store Helm credentials, repository tokens, Grafana passwords, or application secrets in this file.

## Validation and troubleshooting

```bash
kubectl kustomize gitops/dev >/tmp/dev-rendered.yaml
kubectl apply --dry-run=server -f kubernetes/platform/argocd/applications.yaml
kubectl -n argocd get applications
kubectl -n argocd describe application platform-config
```

Common failures are an unchanged example repository URL, a wrong environment path, unavailable chart repository, missing CRD, missing Pod Identity association, or Karpenter discovery tags that do not match the cluster name.
