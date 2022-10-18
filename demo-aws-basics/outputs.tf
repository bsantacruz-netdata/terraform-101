output "subnet_id" {
  description = "Mi Subnet ID"
  value       = aws_subnet.subnet_a.id
}

output "subnet_arn" {
  description = "Mi Subnet ARN"
  value       = aws_subnet.subnet_a.arn
}

# output "vpc_info" {
#   description = "Info de la VPC"
#   value = data.aws_vpc.this
# }