locals {
  vpc              = var.vpc_id
  internet_gateway = var.igw_id
}

#### Associate RT to IGW for AWS Ingress Routing #### 

resource "aws_route_table" "from_igw" {
  vpc_id = local.vpc
  tags   = merge(var.global_tags, { Name = "from_igw" })
}

resource "aws_route_table_association" "from_igw" {
  route_table_id = aws_route_table.from_igw.id
  gateway_id     = local.internet_gateway
}

############################################################
# Security Groups
############################################################

resource "aws_security_group" "this" {
  for_each = var.security_groups

  name   = each.value.name
  vpc_id = local.vpc

  dynamic "ingress" {
    for_each = [
      for rule in each.value.rules :
      rule
      if rule.type == "ingress"
    ]

    content {
      from_port   = ingress.value.from_port
      to_port     = ingress.value.to_port
      protocol    = ingress.value.protocol
      cidr_blocks = ingress.value.cidr_blocks
      description = lookup(ingress.value, "description", "")
    }
  }

  dynamic "egress" {
    for_each = [
      for rule in each.value.rules :
      rule
      if rule.type == "egress"
    ]

    content {
      from_port   = egress.value.from_port
      to_port     = egress.value.to_port
      protocol    = egress.value.protocol
      cidr_blocks = egress.value.cidr_blocks
      description = lookup(egress.value, "description", "")
    }
  }

  tags = merge(var.global_tags, { Name = each.value.name })

  lifecycle {
    create_before_destroy = true
  }
}
