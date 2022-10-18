locals {
  security_group_ids = [
    for k, sg in aws_security_group.this :
  sg.id]
}

data "aws_availability_zones" "available" {
  state = "available"
}

resource "aws_subnet" "this" {
  cidr_block        = var.subnet_cidr
  availability_zone = data.aws_availability_zones.available.names[1]
  vpc_id            = var.vpc_id
  tags              = merge(var.global_tags, { Name = "sn-${var.name}" })
}

resource "aws_route_table" "this" {
  vpc_id = var.vpc_id

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = var.igw_id
  }

  route {
    cidr_block = "10.0.0.0/8"
    transit_gateway_id = var.tgw_id
  }

  route {
    cidr_block = "172.16.0.0/12"
    transit_gateway_id = var.tgw_id
  }

  tags = merge(var.global_tags, { Name = "rt-${var.name}" })
}

resource "aws_route_table_association" "this" {
  subnet_id      = aws_subnet.this.id
  route_table_id = aws_route_table.this.id
  depends_on = [
    aws_subnet.this,
  ]
}

resource "aws_security_group" "this" {
  for_each = var.security_groups
  name     = var.security_group_name
  vpc_id   = var.vpc_id

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

  tags = merge(var.global_tags, { Name = var.security_group_name })

  lifecycle {
    create_before_destroy = true
  }
}

# Panorama AMI ID lookup based on license type, region, version
data "aws_ami" "this" {
  most_recent = true
  owners      = ["aws-marketplace"]

  filter {
    name   = "name"
    values = ["Panorama-AWS-${var.panorama_version}*"]
  }

  filter {
    name   = "product-code"
    values = [var.product_code]
  }
}

# Create the Panorama Instance
resource "aws_instance" "this" {
  ami                                  = data.aws_ami.this.id
  instance_type                        = var.instance_type
  availability_zone                    = data.aws_availability_zones.available.names[1]
  key_name                             = var.ssh_key_name
  private_ip                           = var.mgt_ip
  subnet_id                            = aws_subnet.this.id
  vpc_security_group_ids               = local.security_group_ids
  disable_api_termination              = false
  instance_initiated_shutdown_behavior = "stop"
  ebs_optimized                        = true
  monitoring                           = false
  root_block_device {
    delete_on_termination = true
    tags = merge(var.global_tags, { Name = "vm-${var.name}" })
  }

  tags = merge(var.global_tags, { Name = "vm-${var.name}" })
}


# Create Elastic IP
resource "aws_eip" "this" {
  count = var.create_public_ip ? 1 : 0

  instance = aws_instance.this.id
  vpc      = true

  tags = merge(var.global_tags, { Name = "eip-${var.name}" })
}

# Get the default EBS encryption KMS key in the current region.
data "aws_ebs_default_kms_key" "current" {}

resource "aws_ebs_volume" "this" {
	# checkov:skip=CKV_AWS_3: encrypted = true by variable.
  for_each          = { for k, v in var.ebs_volumes : k => v }
  availability_zone = data.aws_availability_zones.available.names[1]
  size              = try(each.value.ebs_size, "2000")
  encrypted         = try(each.value.ebs_encrypted, true)
  kms_key_id        = try(each.value.ebs_encrypted == false ? null : each.value.kms_key_id != null ? each.value.kms_key_id : data.aws_ebs_default_kms_key.current.key_arn, null)
  tags              = merge(var.global_tags, { Name = try("vm-${each.value.name}", "vm-${var.name}") })
}

resource "aws_volume_attachment" "this" {
  for_each     = { for k, v in var.ebs_volumes : k => v }
  device_name  = each.value.ebs_device_name
  instance_id  = aws_instance.this.id
  volume_id    = aws_ebs_volume.this[each.key].id
  force_detach = try(each.value.force_detach, false)
  skip_destroy = try(each.value.skip_destroy, false)
}