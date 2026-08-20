output "vpc_id" {
  value = aws_vpc.this.id
}
output "vpc_cidr" {
  value = aws_vpc.this.cidr_block
}
output "private_subnet_ids" {
  value = values(aws_subnet.private)[*].id
}
output "public_subnet_ids" {
  value = values(aws_subnet.public)[*].id
}
output "private_route_table_ids" {
  value = values(aws_route_table.private)[*].id
}
output "flow_log_group_arn" {
  value = aws_cloudwatch_log_group.flow_logs.arn
}
