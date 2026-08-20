# Networking

The reference layout uses public subnets for load balancers and private application subnets for EKS nodes. NAT gateways provide controlled egress; VPC endpoints should be enabled for S3, ECR, STS, and CloudWatch in production to reduce exposure and egress cost.

Security groups should allow only cluster control-plane, node, load-balancer, and explicitly required service traffic. Kubernetes NetworkPolicies provide namespace-level isolation after the CNI is installed.
