variable "global_tags" {}
variable "region" {}
variable "cidr_block" {}
variable "vpc_name" {}
variable "vmseries_subnets" {
  default = null
}
variable "tgw_id" {}
variable "tgw_route_tables" {}
variable "tgw_attach_name" {}
variable "panorama_subnet" {}

#####################################################################################

################################ Deploy VPC on AWS ##################################

#####################################################################################

resource "aws_vpc" "this" {
  cidr_block           = var.cidr_block
  tags                 = merge(var.global_tags, { Name = "${var.vpc_name}" })
  enable_dns_support   = true
  enable_dns_hostnames = true
  instance_tenancy     = "default"
}

resource "aws_internet_gateway" "this" {
  vpc_id = aws_vpc.this.id
  tags   = merge(var.global_tags, { Name = "igw-${var.vpc_name}" })
}

resource "aws_ec2_transit_gateway_route_table" "this" {
  for_each           = { for k, v in var.tgw_route_tables : k => v if v.create }
  transit_gateway_id = var.tgw_id
  tags               = merge(var.global_tags, lookup(each.value, "local_tags", {}), { Name = coalesce(lookup(each.value, "name", "")) })
}

#### Flow Logs ####


