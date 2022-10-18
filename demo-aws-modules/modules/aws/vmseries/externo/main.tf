########################################################################
## DEPLOY AWS INFRA ##
########################################################################

module "security_vpc" {
  source          = "../modules/vpc"
  igw_id          = var.igw_id
  vpc_id          = var.vpc_id
  security_groups = var.security_groups
  global_tags     = var.global_tags
}

module "security_subnet_sets" {
  for_each            = toset(distinct([for _, v in var.security_vpc_subnets : v.set]))
  source              = "../modules/subnet_set"
  name                = each.key
  vpc_id              = var.vpc_id
  has_secondary_cidrs = false
  cidrs               = { for k, v in var.security_vpc_subnets : k => v if v.set == each.key }
  global_tags         = {} # No se pueden poner tags por vinculacion con la AWS Lambda de addnics
}

module "natgw_set" {
  # This also a "set" and it means the same thing: we will repeat a nat gateway for each subnet (of the subnet_set).
  source      = "../modules/nat_gateway_set"
  subnets     = module.security_subnet_sets["sn-aws-externo-natgw-pdn"].subnets
  global_tags = var.global_tags
}

### GWLB ###

module "security_gwlb" {
  source      = "../modules/gwlb"
  name        = var.gwlb_name
  vpc_id      = module.security_subnet_sets["sn-aws-externo-gwlb-pdn"].vpc_id
  subnets     = module.security_subnet_sets["sn-aws-externo-gwlb-pdn"].subnets
  global_tags = var.global_tags
}

locals {
  security_vpc_routes = concat(
    [for cidr in var.security_vpc_routes_outbound_destin_cidrs :
      {
        subnet_key   = "sn-fwaws-externo-mng-pdn"
        next_hop_set = module.natgw_set.next_hop_set
        to_cidr = cidr
      }
    ],
    [for cidr in var.security_vpc_mgmt_routes_to_tgw :
      {
        subnet_key   = "sn-fwaws-externo-mng-pdn"
        next_hop_set = var.tgw_next_hop
        to_cidr      = cidr
      }
    ],
    # [for cidr in var.security_vpc_routes_eastwest_cidrs :
    #   {
    #     subnet_key   = "sn-aws-interno-tgw-attach-pdn"
    #     next_hop_set = module.gwlbe_eastwest.next_hop_set
    #     to_cidr      = cidr
    #   }
    # ],
    # [for cidr in var.security_vpc_routes_outbound_destin_cidrs :
    #   {
    #     subnet_key   = "sn-aws-interno-tgw-attach-pdn"
    #     next_hop_set = module.gwlbe_outbound.next_hop_set
    #     to_cidr      = cidr
    #   }
    # ],
    # [for cidr in var.security_vpc_routes_outbound_destin_cidrs :
    #   {
    #     subnet_key   = "sn-aws-interno-gwlbe-outbound-pdn"
    #     next_hop_set = module.natgw_set.next_hop_set
    #     to_cidr      = cidr
    #   }
    # ],
    # [for cidr in var.security_vpc_routes_outbound_source_cidrs :
    #   {
    #     subnet_key   = "sn-aws-interno-gwlbe-outbound-pdn"
    #     next_hop_set = var.tgw_next_hop
    #     to_cidr      = cidr
    #   }
    # ],
    # [for cidr in var.security_vpc_routes_eastwest_cidrs :
    #   {
    #     subnet_key   = "sn-aws-interno-gwlbe-eastwest-pdn"
    #     next_hop_set = var.tgw_next_hop
    #     to_cidr      = cidr
    #   }
    # ],
    [for cidr in var.security_vpc_routes_outbound_destin_cidrs :
      {
        subnet_key = "sn-aws-externo-natgw-pdn"
        next_hop_set = {
          type = "internet_gateway"
          id   = var.igw_id
          ids  = {}
        }
        to_cidr = cidr
      }
    ],
    # [for cidr in var.security_vpc_routes_outbound_source_cidrs :
    #   {
    #     subnet_key   = "sn-aws-interno-natgw-pdn"
    #     next_hop_set = module.gwlbe_outbound.next_hop_set
    #     to_cidr      = cidr
    #   }
    # ],
  )
}

module "security_vpc_routes" {
  for_each        = { for route in local.security_vpc_routes : "${route.subnet_key}_${route.to_cidr}" => route }
  source          = "../modules/vpc_route"
  route_table_ids = module.security_subnet_sets[each.value.subnet_key].unique_route_table_ids
  to_cidr         = each.value.to_cidr
  next_hop_set    = each.value.next_hop_set
}