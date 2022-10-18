#####################################################################################
################################# DEPLOY AWS INFRA ##################################
#####################################################################################
provider "aws" {
  region = var.region
}

module "aws-network" {
  source          = "./modules/aws/network"
  region          = var.region
  global_tags     = var.global_tags
  tgw_id          = var.tgw_id
  panorama_subnet = module.aws-panorama.subnet
  vpc_name        = "demo-terraform101-modules"
  cidr_block      = "10.69.0.0/19"
  tgw_attach_name = "security-vpc-attachment"
  tgw_route_tables = {
    "from_security_vpc" = {
      create = true
      name   = "from_security"
    }
    "from_spoke_vpc" = {
      create = true
      name   = "from_spokes"
    }
  }
}

module "aws-panorama" {
  source              = "./modules/aws/panorama"
  region              = var.region
  global_tags         = var.global_tags
  panorama_version    = var.panorama_version
  vpc_name            = module.aws-network.vpc_name
  vpc_id              = module.aws-network.vpc_id
  igw_id              = module.aws-network.igw_id
  tgw_id              = var.tgw_id
  name                = "aws-panorama-pdn-01"
  subnet_cidr         = "10.69.21.128/26"
  instance_type       = "m5.2xlarge"
  ssh_key_name        = "panorama-deploy"
  mgt_ip              = "10.69.21.140"
  create_public_ip    = false
  security_group_name = "nsg-aws-panorama-mng-pdn"
  ebs_volumes = [
    {
      name            = "aws-panorama-pdn-01-log-disk"
      ebs_device_name = "/dev/sdb"
      ebs_size        = "2000"
      ebs_encrypted   = true
      kms_key_id      = ""
    },
  ]
  security_groups = {
    panorama_mgmt = {
      name = "nsg-panorama-mgt"
      rules = {
        all_outbound = {
          description = "Permit All traffic outbound"
          type        = "egress", from_port = "0", to_port = "0", protocol = "-1"
          cidr_blocks = ["0.0.0.0/0"]
        }
        https = {
          description = "Permit HTTPS"
          type        = "ingress", from_port = "443", to_port = "443", protocol = "tcp"
          cidr_blocks = ["10.0.0.0/8", "172.16.0.0/12", "192.168.0.0/16"] # Privates Only
        }
        ssh = {
          description = "Permit SSH"
          type        = "ingress", from_port = "22", to_port = "22", protocol = "tcp"
          cidr_blocks = ["10.0.0.0/8", "172.16.0.0/12", "192.168.0.0/16"] # Privates Only
        }
        icmp = {
          description = "Permit ICMP"
          type        = "ingress", from_port = "-1", to_port = "-1", protocol = "icmp"
          cidr_blocks = ["10.0.0.0/8", "172.16.0.0/12", "192.168.0.0/16"] # Privates Only
        }
      }
    }
  }
}