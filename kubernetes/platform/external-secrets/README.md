# External Secrets and AWS Secrets Manager

This directory configures the cluster-side reference to AWS Secrets Manager. It allows Kubernetes workloads to consume centrally managed secrets without committing secret values to Git.

## How it works

Argo CD installs External Secrets Operator from the pinned Helm chart in `kubernetes/platform/argocd/applications.yaml`. The `ClusterSecretStore` in this directory tells the operator to use AWS Secrets Manager in `us-east-1`. Individual applications should add `ExternalSecret` resources that reference approved secret names and materialize namespace-local Kubernetes Secrets.

The store contains no credentials. Authentication is expected to come from the AWS SDK credential chain through an EKS Pod Identity associated with the External Secrets service account.

## Required operator configuration

Before using the store:

1. create a dedicated IAM role through the Terraform IAM module;
2. associate it with the exact External Secrets namespace and service-account name installed by the Helm chart;
3. allow only `secretsmanager:GetSecretValue` and `secretsmanager:DescribeSecret` for approved secret ARNs;
4. change the region in `cluster-secret-store.yaml` if the environment uses another region;
5. verify the `ClusterSecretStore` reports `Ready=True`.

Example workload secret reference:

```yaml
apiVersion: external-secrets.io/v1beta1
kind: ExternalSecret
metadata:
  name: model-server-runtime
  namespace: model-serving
spec:
  refreshInterval: 1h
  secretStoreRef:
    kind: ClusterSecretStore
    name: aws-secrets-manager
  target:
    name: model-server-runtime
  data:
    - secretKey: api-key
      remoteRef:
        key: <ENVIRONMENT>/model-server
        property: api-key
```

The example is intentionally not part of the default Kustomization because no application secret is required for the mocked model server.

## Security and operations

- Keep secret values and generated Kubernetes Secret manifests out of Git.
- Separate secret paths and IAM roles by environment.
- Use KMS encryption, Secrets Manager rotation, and CloudTrail auditing.
- Avoid wildcard secret resources unless an AWS API operation requires them.
- Restrict which namespaces may reference a cluster-wide store, or replace it with namespace-scoped `SecretStore` resources for stronger tenant isolation.
- Understand that deleting an `ExternalSecret` may delete or orphan its generated Kubernetes Secret depending on its creation and deletion policies.

## Validation and troubleshooting

```bash
kubectl kustomize kubernetes/platform/external-secrets
kubectl get clustersecretstore aws-secrets-manager
kubectl describe clustersecretstore aws-secrets-manager
kubectl -n external-secrets logs deployment/external-secrets
```

`AccessDenied` normally indicates an incorrect Pod Identity association or IAM resource ARN. `SecretSyncedError` usually indicates a missing remote key/property, wrong region, or KMS decrypt restriction.
