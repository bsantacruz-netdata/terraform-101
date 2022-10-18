#### PA VM AMI ID Lookup based on license type, region, version ####
data "aws_ami" "pa_vm" {
  count = var.vmseries_ami_id != null ? 0 : 1

  most_recent = true
  owners      = ["aws-marketplace"]

  filter {
    name   = "name"
    values = ["PA-VM-AWS-${var.vmseries_version}*"]
  }
  filter {
    name   = "product-code"
    values = [var.vmseries_product_code]
  }
}

# Create launch template with a single interface
resource "aws_launch_template" "this" {
  name          = "${var.name_prefix}template1"
  ebs_optimized = true
  image_id      = data.aws_ami.pa_vm[0].id
  instance_type = var.instance_type
  key_name      = var.ssh_key_name
  tags          = merge(var.global_tags)
  vpc_security_group_ids = [var.security_group_ids[0]] 
  
  iam_instance_profile {
    name = var.iam_instance_profile
  }
  tag_specifications {
    resource_type = "instance"

    tags = merge(var.global_tags,{Name:"${var.name_prefix}asg"})
  }
  user_data = base64encode(var.bootstrap_options)
}

locals {
  asg_tags = [
    for k, v in var.global_tags : {
      key                 = k
      value               = v
      propagate_at_launch = true
    }
  ]
}

# Create autoscaling group based on launch template and ALL subnets from var.interfaces
resource "aws_autoscaling_group" "this" {
  name                      = "${var.name_prefix}${var.asg_name}"
  vpc_zone_identifier       = concat([for v in var.data_subnets : v.id])
  desired_capacity          = var.desired_capacity
  max_size                  = var.max_size
  min_size                  = var.min_size
  tags                      = local.asg_tags
  target_group_arns         = var.target_group_arns
  # health_check_type         = "ELB"
  health_check_grace_period = "900"
  termination_policies      = ["NewestInstance"]

  launch_template {
    id      = aws_launch_template.this.id
    version = "$Latest"
  }

  dynamic "warm_pool" {
    for_each = var.max_group_prepared_capacity > 0 ? ["this"] : [] # the empty list [] disables it

    content {
      pool_state                  = var.warm_pool_state
      min_size                    = var.warm_pool_min_size
      max_group_prepared_capacity = var.max_group_prepared_capacity
    }
  }
}

# Add lifecycle hook to autoscaling group
resource "aws_autoscaling_lifecycle_hook" "this" {
  name                   = "${var.name_prefix}hook1"
  autoscaling_group_name = aws_autoscaling_group.this.name
  default_result         = "CONTINUE"
  heartbeat_timeout      = var.lifecycle_hook_timeout
  lifecycle_transition   = "autoscaling:EC2_INSTANCE_LAUNCHING"
}

# IAM role that will be used for Lambda function
resource "aws_iam_role" "this" {
  name               = "${var.name_prefix}lambda_iam_role"
  assume_role_policy = <<EOF
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Action": "sts:AssumeRole",
      "Principal": {
        "Service": "lambda.amazonaws.com"
      },
      "Effect": "Allow",
      "Sid": ""
    }
  ]
}
EOF
}

# Attach IAM Policy to IAM role for Lambda
resource "aws_iam_role_policy" "this" {
  name   = "${var.name_prefix}lambda_iam_policy"
  role   = aws_iam_role.this.id
  policy = <<-EOF
{
    "Version": "2012-10-17",
    "Statement": [
        {
            "Action": [
                "logs:CreateLogGroup",
                "logs:CreateLogStream",
                "logs:PutLogEvents"
            ],
            "Effect": "Allow",
            "Resource": "arn:aws:logs:*:*:*"
        },
        {
            "Action": [
                "ec2:CreateNetworkInterface",
                "ec2:DescribeNetworkInterfaces",
                "ec2:DetachNetworkInterface",
                "ec2:DeleteNetworkInterface",
                "ec2:ModifyNetworkInterfaceAttribute",
                "ec2:DescribeSubnets",
                "ec2:AttachNetworkInterface",
                "ec2:DescribeInstances",
                "autoscaling:CompleteLifecycleAction",
                "autoscaling:DescribeAutoScalingGroups"
            ],
            "Effect": "Allow",
            "Resource": "*"
        }
    ]
}
EOF
}

data "archive_file" "lambda_zip" {
  type        = "zip"
  source_file  = "${path.module}/lambda.py"
  output_path = "${path.module}/lambda.zip"
}

resource "aws_lambda_function" "this" {
  function_name    = "${var.name_prefix}add_nics"
  role             = aws_iam_role.this.arn
  handler          = "lambda.lambda_handler"
  filename         = data.archive_file.lambda_zip.output_path
  source_code_hash = data.archive_file.lambda_zip.output_base64sha256
  runtime          = "python3.8"
  tags             = var.global_tags
  environment {
    variables = {
      security_group_ids = var.security_group_ids[1]
      # mgmt_subnets = var.mgmt_subnets
    }
  }
}

resource "aws_lambda_permission" "this" {
  action              = "lambda:InvokeFunction"
  function_name       = aws_lambda_function.this.function_name
  principal           = "events.amazonaws.com"
  statement_id_prefix = var.name_prefix
}

resource "aws_cloudwatch_event_rule" "this" {
  name          = "${var.name_prefix}add_nics"
  tags          = var.global_tags
  event_pattern = <<EOF
{
  "source": [
    "aws.autoscaling"
  ],
  "detail-type": [
    "EC2 Instance-launch Lifecycle Action"
  ],
  "detail": {
    "AutoScalingGroupName": [
      "${aws_autoscaling_group.this.name}"
    ]
  }
}
EOF
}

resource "aws_cloudwatch_event_target" "this" {
  rule      = aws_cloudwatch_event_rule.this.name
  target_id = "${var.name_prefix}add_nics"
  arn       = aws_lambda_function.this.arn
}

resource "aws_autoscaling_policy" "scale-out" {
  name                   = "${var.name_prefix}scale-out"
  scaling_adjustment     = 1
  adjustment_type        = "ChangeInCapacity"
  cooldown               = 900
  autoscaling_group_name = aws_autoscaling_group.this.name
}

resource "aws_cloudwatch_metric_alarm" "scale-out" {
  alarm_name          = "${var.name_prefix}cpu-high"
  comparison_operator = "GreaterThanOrEqualToThreshold"
  evaluation_periods  = "1"
  metric_name         = var.metric_alarm
  namespace           = var.metric_namespace
  period              = var.ScalingPeriod
  statistic           = "Average"
  threshold           = var.ScaleUpThreshold
  # tags                = var.global_tags

  # dimensions = {
  #   AutoScalingGroupName = aws_autoscaling_group.this.name
  # }

  alarm_description = "This metric monitors VM-Series ${var.metric_alarm} utilization to Scale Out (add) instances."
  alarm_actions     = [aws_autoscaling_policy.scale-out.arn]
}

# ESTAS SON LAS ALARMAS Y POLITICAS DE AUTOSCALAMIENTO PARA "SCALE-IN" PERO DESAHBILITADAS PORQUE SE REALIZARIA MANUAL

# resource "aws_autoscaling_policy" "scale-in" {
#   name                   = "${var.name_prefix}scale-in"
#   scaling_adjustment     = -1
#   adjustment_type        = "ChangeInCapacity"
#   cooldown               = 900
#   autoscaling_group_name = aws_autoscaling_group.this.name
# }

# resource "aws_cloudwatch_metric_alarm" "scale-in" {
#   alarm_name          = "${var.name_prefix}cpu-low"
#   comparison_operator = "LessThanOrEqualToThreshold"
#   evaluation_periods  = "1"
#   metric_name         = var.metric_alarm
#   namespace           = var.metric_namespace
#   period              = var.ScalingPeriod
#   statistic           = "Average"
#   threshold           = var.ScaleDownThreshold
#   # tags                = var.global_tags

#   # dimensions = {
#   #   AutoScalingGroupName = aws_autoscaling_group.this.name
#   # }

#   alarm_description = "This metric monitors VM-Series ${var.metric_alarm} utilization to Scale In (remove) instances."
#   # alarm_actions     = [aws_autoscaling_policy.scale-in.arn]
# }