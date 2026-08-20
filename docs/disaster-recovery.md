# Disaster Recovery

Terraform state must use a versioned, encrypted S3 backend with a locking mechanism. Keep environment configuration in version control and back up application data outside the cluster.

Recovery sequence:

1. Restore the Terraform state backend and AWS prerequisites.
2. Recreate the VPC and EKS environment from the selected environment root.
3. Install Argo CD and restore the environment ApplicationSet.
4. Reconcile platform operators, secrets references, and workloads.
5. Verify metrics, traces, logs, replicas, and external dependencies.

Run recovery exercises periodically and record RTO/RPO results in an ADR.
