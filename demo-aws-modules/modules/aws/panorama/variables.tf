
variable "region" {}

variable "vpc_name" {}
variable "tgw_id" {}

# General
variable "name" {
  description = "Name for the Panorama instance."
  type        = string
  default     = "pan-panorama"
}

variable "global_tags" {
  description = <<-EOF
  A map of tags to assign to the resources.
  If configured with a provider `default_tags` configuration block present, tags with matching keys will overwrite those defined at the provider-level."
  EOF
  default     = {}
  type        = map(any)
}

# Panorama
variable "product_code" {
  description = "Product code for Panorama BYOL license."
  type        = string
  default     = "eclz7j04vu9lf8ont8ta3n17o"
}

variable "panorama_version" {
  description = <<-EOF
  Panorama PAN-OS Software version. List published images with: 
  ```
  aws ec2 describe-images \\
  --filters "Name=product-code,Values=eclz7j04vu9lf8ont8ta3n17o" "Name=name,Values=Panorama-AWS*" \\
  --output json --query "Images[].Description" \| grep -o 'Panorama-AWS-.*' \| tr -d '",'
  ```
  EOF
  default     = "10.0.6"
  type        = string
}

variable "instance_type" {
  description = "EC2 instance type for Panorama. Default set to Palo Alto Networks recommended instance type."
  type        = string
  default     = "c5.4xlarge"
}

variable "ssh_key_name" {
  description = "AWS EC2 key pair name."
  type        = string
}

variable "create_public_ip" {
  description = "If true, create an Elastic IP address for Panorama."
  type        = bool
  default     = false
}

variable "mgt_ip" {
  description = "If provided, associates a private IP address to the Panorama instance."
  type        = string
  default     = null
}

variable "vpc_id" {
  description = "VPC ID to launch Panorama in."
  type        = string
}

variable "subnet_cidr" {}

variable "security_groups" {
  description = <<EOF
  The `security_groups` variable is a map of maps, where each map represents an AWS Security Group.
  The key of each entry acts as the Security Group name.
  List of available attributes of each Security Group entry:
  - `rules`: A list of objects representing a Security Group rule. The key of each entry acts as the name of the rule and
      needs to be unique across all rules in the Security Group.
      List of attributes available to define a Security Group rule:
      - `description`: Security Group description.
      - `type`: Specifies if rule will be evaluated on ingress (inbound) or egress (outbound) traffic.
      - `cidr_blocks`: List of CIDR blocks - for ingress, determines the traffic that can reach your instance. For egress
      Determines the traffic that can leave your instance, and where it can go.
  Example:
  ```
  security_groups = {
    vmseries-mgmt = {
      name = "vmseries-mgmt"
      rules = {
        all-outbound = {
          description = "Permit All traffic outbound"
          type        = "egress", from_port = "0", to_port = "0", protocol = "-1"
          cidr_blocks = ["0.0.0.0/0"]
        }
        https-inbound-private = {
          description = "Permit HTTPS for VM-Series Management"
          type        = "ingress", from_port = "443", to_port = "443", protocol = "tcp"
          cidr_blocks = ["10.0.0.0/8"]
        }
        https-inbound-eip = {
          description = "Permit HTTPS for VM-Series Management from known public IPs"
          type        = "ingress", from_port = "443", to_port = "443", protocol = "tcp"
          cidr_blocks = ["100.100.100.100/32"]
        }
        ssh-inbound-eip = {
          description = "Permit SSH for VM-Series Management from known public IPs"
          type        = "ingress", from_port = "22", to_port = "22", protocol = "tcp"
          cidr_blocks = ["100.100.100.100/32"]
        }
      }
    }
  }
  ```
  EOF

  default = {}
  type    = any
}

variable "ebs_volumes" {
  description = <<-EOF
  List of EBS volumes to create and attach to Panorama.
  Available options:
  - `name`              (Optional) Name tag for the EBS volume. If not provided defaults to the value of `var.name`.
  - `ebs_device_name`   (Required) The EBS device name to expose to the instance (for example, /dev/sdh or xvdh). 
  See [Device Naming on Linux Instances](https://docs.aws.amazon.com/AWSEC2/latest/UserGuide/device_naming.html#available-ec2-device-names) for more information.
  - `ebs_size`          (Optional) The size of the EBS volume in GiBs. Defaults to 2000 GiB.
  - `ebs_encrypted`     (Optional) If true, the Panorama EBS volume will be encrypted.
  - `force_detach`      (Optional) Set to true if you want to force the volume to detach. Useful if previous attempts failed, but use this option only as a last resort, as this can result in data loss.
  - `skip_destroy`      (Optional) Set this to true if you do not wish to detach the volume from the instance to which it is attached at destroy time, and instead just remove the attachment from Terraform state. 
  This is useful when destroying an instance attached to third-party volumes.
  - `kms_key_id`        (Optional) The ARN for the KMS encryption key. When specifying `kms_key_id`, the `ebs_encrypted` variable needs to be set to true.
  If the `kms_key_id` is not provided but the `ebs_encrypted` is set to `true`, the default EBS encryption KMS key in the current region will be used.
  
  Note: Terraform must be running with credentials which have the `GenerateDataKeyWithoutPlaintext` permission on the specified KMS key 
  as required by the [EBS KMS CMK volume provisioning process](https://docs.aws.amazon.com/kms/latest/developerguide/services-ebs.html#ebs-cmk) to prevent a volume from being created and almost immediately deleted.
  If null, the default EBS encryption KMS key in the current region is used.

  Example:
  ```
  ebs_volumes = [
    {
      name              = "ebs-1"
      ebs_device_name   = "/dev/sdb"
      ebs_size          = "2000"
      ebs_encrypted     = true
      kms_key_id        = "arn:aws:kms:us-east-1:111122223333:key/1234abcd-12ab-34cd-56ef-1234567890ab"
    },
    {
      name              = "ebs-2"
      ebs_device_name   = "/dev/sdb"
      ebs_size          = "2000"
      ebs_encrypted     = true
    },
    {
      name              = "ebs-3"
      ebs_device_name   = "/dev/sdb"
      ebs_size          = "2000"
    },
  ]
  ```
  EOF
  default     = []
}

variable "security_group_name" {}
variable "igw_id" {}
