module "bootstrap" {
  source        = "../modules/bootstrap"
  prefix        = var.name_prefix
  bootstrapping = var.bootstrapping
  global_tags   = var.global_tags
}

resource "aws_key_pair" "this" {
  count = var.create_ssh_key ? 1 : 0

  key_name   = var.ssh_key_name
  public_key = file(var.ssh_public_key_path)
  tags       = var.global_tags
}

module "asg" {
  instance_type               = var.instance_type
  vmseries_version            = var.vmseries_version
  source                      = "../modules/asg"
  desired_capacity            = var.desired_capacity
  max_size                    = var.max_size
  min_size                    = var.min_size
  max_group_prepared_capacity = var.max_group_prepared_capacity
  warm_pool_state             = var.warm_pool_state
  warm_pool_min_size          = var.warm_pool_min_size
  target_group_arns           = [module.security_gwlb.target_group.arn]
  data_subnets                = module.security_subnet_sets["sn-fwaws-externo-data-pdn"].subnets
  mgmt_subnets                = module.security_subnet_sets["sn-fwaws-externo-mng-pdn"].subnets
  security_group_ids          = concat([module.security_vpc.security_group_ids["vmseries_data"]], [module.security_vpc.security_group_ids["vmseries_mgmt"]])
  ScaleUpThreshold            = var.ScaleUpThreshold
  ScaleDownThreshold          = var.ScaleDownThreshold
  ScalingPeriod               = var.ScalingPeriod
  metric_alarm                = var.metric_alarm
  metric_namespace            = var.metric_namespace
  name_prefix                 = var.name_prefix
  bootstrap_options = join(";", compact(concat(
    ["vmseries-bootstrap-aws-s3bucket=${module.bootstrap.bucket_name}"],
    [for k, v in var.vmseries_common.bootstrap_options : "${k}=${v}"],
  )))

  iam_instance_profile = module.bootstrap.instance_profile_name
  ssh_key_name         = var.ssh_key_name
  global_tags          = var.global_tags
}