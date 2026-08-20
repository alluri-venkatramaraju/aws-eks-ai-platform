# Security

- Keep EKS nodes in private subnets; expose only reviewed load balancers.
- Use EKS Pod Identity or IRSA for AWS APIs and grant narrowly scoped permissions.
- Encrypt EKS secrets and Terraform state with KMS.
- Store runtime secrets in AWS Secrets Manager and sync them with External Secrets.
- Apply default-deny network policies and explicitly allow required traffic.
- Scan Terraform with Checkov, images with Trivy, and manifests with kubeconform.
- The container workflow signs published images keylessly with Cosign and emits BuildKit provenance and an SBOM. Before admitting production workloads, configure Kyverno or Gatekeeper to verify the GitHub Actions OIDC identity and require digest-pinned images.
- Enable EKS audit, API, authenticator, scheduler, and controller-manager logs.

No secret, private key, AWS account ID, customer data, or real domain may be committed.
