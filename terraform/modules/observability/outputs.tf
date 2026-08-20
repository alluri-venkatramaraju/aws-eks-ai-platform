output "application_log_group_arn" {
  value = aws_cloudwatch_log_group.application.arn
}
output "otel_log_group_arn" {
  value = aws_cloudwatch_log_group.otel.arn
}