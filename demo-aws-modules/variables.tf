#####################################################################################
################################## GENERAL VARIABLES ################################
#####################################################################################

variable "global_tags" {}
variable "panorama_version" {
  description = <<-EOF
  Panorama PAN-OS Software version. List published images with: 
  ```
  aws ec2 describe-images --filters "Name=product-code,Values=eclz7j04vu9lf8ont8ta3n17o" "Name=name,Values=Panorama-AWS*" --output json --query "Images[].Description" | grep -o 'Panorama-AWS-.*' | tr -d '",'
  ```
  EOF
  type        = string
}

#####################################################################################
#################################### AWS VARIABLES ##################################
#####################################################################################

variable "region" {}

## Transit gateway 
variable "tgw_id" {}