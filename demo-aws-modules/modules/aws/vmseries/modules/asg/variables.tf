variable "vmseries_version" {
  description = <<-EOF
  VM-Series Firewall version to deploy.
  To list all available VM-Series versions, run the command provided below. 
  Please have in mind that the `product-code` may need to be updated - check the `vmseries_product_code` variable for more information.
  ```
  aws ec2 describe-images --region us-west-1 --filters "Name=product-code,Values=6njl1pau431dv1qxipg63mvah" "Name=name,Values=PA-VM-AWS*" --output json --query "Images[].Description" \| grep -o 'PA-VM-AWS-.10.1.3' \| sort
  ```
  EOF
  default     = "10.1.5"
  type        = string
}

variable "fw_license_type" {
  description = "Select License type (byol/payg1/payg2)."
  default     = "byol"
}

variable "vmseries_ami_id" {
  description = <<-EOF
  Specific AMI ID to use for VM-Series instance.
  If `null` (the default), `vmseries_version` and `vmseries_product_code` vars are used to determine a public image to use.
  EOF
  default     = null
  type        = string
}

variable "vmseries_product_code" {
  description = <<-EOF
  Product code corresponding to a chosen VM-Series license type model - by default - BYOL. 
  To check the available license type models and their codes, please refer to the
  [VM-Series documentation](https://docs.paloaltonetworks.com/vm-series/10-0/vm-series-deployment/set-up-the-vm-series-firewall-on-aws/deploy-the-vm-series-firewall-on-aws/obtain-the-ami/get-amazon-machine-image-ids.html)
  EOF
  default     = "6njl1pau431dv1qxipg63mvah"
  type        = string
}

variable "instance_type" {
  description = "EC2 Instance Type."
  default     = "m5.xlarge"
  type        = string
}

variable "name_prefix" {
  description = "All resource names will be prepended with this string."
  type        = string
}

variable "asg_name" {
  description = "Name of the autoscaling group to create."
  default     = "asg"
  type        = string
}

variable "ssh_key_name" {
  description = "Name of AWS keypair to associate with instances."
  type        = string
}

variable "bootstrap_options" {
  description = <<-EOF
  VM-Series bootstrap options to provide using instance user data. Contents determine type of bootstap method to use.
  If empty (the default), bootstrap process is not triggered at all.
  For more information on available methods, please refer to VM-Series documentation for specific version.
  For 10.0 docs are available [here](https://docs.paloaltonetworks.com/vm-series/10-0/vm-series-deployment/bootstrap-the-vm-series-firewall.html).
  EOF
  default     = ""
  type        = string
}

variable "lifecycle_hook_timeout" {
  description = "How long should we wait in seconds for the Lambda hook to finish."
  type        = number
  default     = 300
}

variable "desired_capacity" {
  type    = number
  default = 2
}

variable "max_size" {
  type    = number
  default = 2
}

variable "min_size" {
  type    = number
  default = 1
}

variable "warm_pool_state" {
  description = "See the [provider's documentation](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/autoscaling_group#warm_pool). Ignored when `max_group_prepared_capacity` is 0 (the default value)."
  default     = null
}

variable "warm_pool_min_size" {
  description = "See the [provider's documentation](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/autoscaling_group#warm_pool). Ignored when `max_group_prepared_capacity` is 0 (the default value)."
  default     = null
}

variable "max_group_prepared_capacity" {
  description = "Set to non-zero to activate the Warm Pool of instances. See the [provider's documentation](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/autoscaling_group#warm_pool)."
  default     = 0
}

variable "global_tags" {
  description = "Map of additional tags to apply to all resources."
  default     = {}
  type        = map(any)
}

variable "iam_instance_profile" {
  description = "IAM instance profile."
  default     = null
  type        = string
}

variable "target_group_arns" {}

variable "data_subnets" {}
variable "mgmt_subnets" {}
variable "security_group_ids" {}

variable "ScaleUpThreshold" {}
variable "ScaleDownThreshold" {}
variable "ScalingPeriod" {}
variable "metric_alarm" {}
variable "metric_namespace" {}
