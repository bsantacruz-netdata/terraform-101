########################################################################

## AWS VPC Variables Definition ##

########################################################################

variable "global_tags" {
  description = "Map of tags to assign to all of the created resources."
  type        = map(any)
}
variable "region" {}
variable "vpc_id" {}
variable "igw_id" {}
variable "security_groups" {}
variable "security_vpc_subnets" {}

########################################################################

## Transit gateway ##

########################################################################

variable "tgw_id" {}
variable "tgw_next_hop" {}

########################################################################

## VM-Series instances ##

########################################################################

variable "name_prefix" {}
variable "vmseries_common" {}
variable "create_ssh_key" {}
variable "ssh_key_name" {}
variable "ssh_public_key_path" {}
variable "instance_type" {}
variable "vmseries_version" {}
variable "bootstrapping" {}

########################################################################

## GWLB ##

########################################################################

variable "gwlb_name" {}

# Security VPC Routes

variable "security_vpc_routes_outbound_destin_cidrs" {
  description = <<-EOF
  From the perspective of Security VPC, the destination addresses of packets coming from TGW and flowing outside. 
  A list of strings, for example `[\"0.0.0.0/0\"]`.
  EOF
  type        = list(string)
}

variable "security_vpc_mgmt_routes_to_tgw" {
  description = <<-EOF
  The eastwest inspection of traffic heading to VM-Series management interface is not possible. 
  Due to AWS own limitations, anything from the TGW destined for the management interface could *not* possibly override LocalVPC route. 
  Henceforth no management routes go back to gwlbe_eastwest.
  EOF
  type        = list(string)
}

# ASG

variable "desired_capacity" {}
variable "max_size" {}
variable "min_size" {}
variable "max_group_prepared_capacity" {}
variable "warm_pool_state" {}
variable "warm_pool_min_size" {}

variable "ScaleUpThreshold" {}
variable "ScaleDownThreshold" {}
variable "ScalingPeriod" {}
variable "metric_alarm" {}
variable "metric_namespace" {}