# Workload IAM and EKS Pod Identity module

This module gives Kubernetes service accounts narrowly scoped AWS permissions without static access keys and without placing application permissions on an EC2 node role.

## How it works

For each entry in `workloads`, the module creates:

1. an IAM role trusted by `pods.eks.amazonaws.com` for `sts:AssumeRole` and session tagging;
2. an inline policy assembled from caller-supplied statements;
3. an EKS Pod Identity association binding the role to one namespace and service account.

The EKS Pod Identity Agent is installed by the EKS module. At runtime, the AWS SDK obtains short-lived credentials for the pod's associated role.

## Inputs and outputs

| Name | Required/default | Purpose |
| --- | --- | --- |
| `cluster_name` | required | Target EKS cluster and IAM role-name prefix. |
| `workloads` | `{}` | Map of namespace, service account, and IAM policy statements. |
| `tags` | `{}` | Additional IAM role tags. |

`role_arns` returns a map keyed by the workload names supplied by the caller.

## Usage

```hcl
module "workload_iam" {
  source = "../../modules/iam"

  cluster_name = module.eks.cluster_name
  workloads = {
    external-secrets = {
      namespace       = "external-secrets"
      service_account = "external-secrets"
      policy_statements = [{
        Effect   = "Allow"
        Action   = ["secretsmanager:GetSecretValue", "secretsmanager:DescribeSecret"]
        Resource = ["arn:aws:secretsmanager:us-east-1:<AWS_ACCOUNT_ID>:secret:dev/*"]
      }]
    }
  }
  tags = local.tags
}
```

The service account must exist with exactly the configured namespace and name. The association can be created before the service account, but credentials will not be delivered until the workload uses the matching identity.

## Least-privilege guidance

- Create one role per workload or controller responsibility.
- Scope resource ARNs to the environment and application.
- Avoid `Action = ["*"]` and `Resource = ["*"]`.
- Separate read, write, and administrative roles.
- Review CloudTrail activity and remove unused permissions.
- Do not add permissions to a node role to work around an association error.

Some AWS APIs do not support resource-level permissions. When a wildcard is unavoidable, constrain access with IAM conditions such as resource tags, region, source VPC endpoint, or request attributes.

## Troubleshooting

If a pod receives `AccessDenied`, confirm the policy action and resource ARN first. If it reports no credentials, verify the Pod Identity Agent, association, cluster name, namespace, service account, and AWS SDK support. Recreated service accounts with the same name continue to match because association is name-based.

Destroying an association stops new credential delivery, but already issued credentials remain valid until their short expiration.
