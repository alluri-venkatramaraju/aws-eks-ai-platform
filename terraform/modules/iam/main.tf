data "aws_iam_policy_document" "pod_identity" {
  statement {
    actions = ["sts:AssumeRole", "sts:TagSession"]
    principals {
      type        = "Service"
      identifiers = ["pods.eks.amazonaws.com"]
    }
  }
}
resource "aws_iam_role" "workload" {
  for_each           = var.workloads
  name               = "${var.cluster_name}-${each.key}"
  assume_role_policy = data.aws_iam_policy_document.pod_identity.json
  tags               = var.tags
}
resource "aws_iam_role_policy" "workload" {
  for_each = var.workloads
  name     = "least-privilege"
  role     = aws_iam_role.workload[each.key].id
  policy = jsonencode({ Version = "2012-10-17", Statement = each.value.policy_statements
  })
}
resource "aws_eks_pod_identity_association" "workload" {
  for_each        = var.workloads
  cluster_name    = var.cluster_name
  namespace       = each.value.namespace
  service_account = each.value.service_account
  role_arn        = aws_iam_role.workload[each.key].arn
}