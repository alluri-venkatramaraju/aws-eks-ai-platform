# Architecture

## Boundaries

Terraform owns AWS infrastructure and cluster bootstrap inputs. Argo CD owns Kubernetes platform components and workloads after the cluster is reachable. Applications are stateless and receive configuration through environment variables and workload identity.

## Workload Classes

- System: critical platform services on on-demand capacity.
- CPU: general inference and controllers.
- Memory: data preparation and memory-heavy inference.
- GPU: optional accelerated inference or training, tainted and disabled by default.
- Spot: interruptible batch workloads.

Pods express the class with node affinity, tolerations, and resource requests. Karpenter provisions only the capacity required by pending pods.

## Availability

The VPC spans multiple Availability Zones. Worker nodes use private subnets and topology spread constraints. Pod disruption budgets protect serving replicas during voluntary disruption.

## Data Flow

Requests reach the model-serving service through an ingress or internal load balancer. The service emits JSON logs, Prometheus metrics, and OTLP traces. Secrets are referenced through External Secrets and AWS Secrets Manager rather than stored in manifests.
