output "vpc_id" {
  description = "Security VPC ID on AWS"
  value       = aws_vpc.this.id
}

output "vpc_name" {
  description = "Security VPC Name on AWS"
  value       = var.vpc_name
}

output "igw_id" {
  description = "Internet Gateway ID VPC on AWS"
  value       = aws_internet_gateway.this.id
}

output "vpc_cidr" {
  description = "CIDR Block for Security VPC on AWS"
  value       = var.cidr_block
}