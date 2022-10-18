resource "random_id" "bucket_id" {
  byte_length = 8
}

resource "aws_s3_bucket" "this" {
  # checkov:skip=CKV_AWS_20: There is a aws_s3_bucket_acl with "private" statement
  # checkov:skip=CKV_AWS_57: There is a aws_s3_bucket_acl with "private" statement
  bucket            = "${var.prefix}${random_id.bucket_id.hex}"
  force_destroy     = var.force_destroy
  tags              = var.global_tags
}

resource "aws_s3_bucket_acl" "bucket_acl" {
  bucket = aws_s3_bucket.this.id
  acl    = "private"
}

resource "aws_s3_bucket_public_access_block" "app" {
  bucket = aws_s3_bucket.this.id
  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true
}

resource "aws_s3_bucket_object" "bootstrap_dirs" {
  for_each = toset(var.bootstrap_directories)
  bucket  = aws_s3_bucket.this.id
  key     = each.value
  content = "/dev/null"
}

resource "aws_s3_bucket_object" "init_cfg" {
  count  = false ? 0 : 1
  bucket = aws_s3_bucket.this.id
  key    = "config/init-cfg.txt"
  content = templatefile("${path.module}/init-cfg.txt.tmpl",
    {
      "hostname"           = var.bootstrapping.hostname,
      "panorama-server"    = var.bootstrapping.panorama-server,
      "panorama-server2"   = var.bootstrapping.panorama-server2,
      "tplname"            = var.bootstrapping.tplname,
      "dgname"             = var.bootstrapping.dgname,
      "cgname"             = var.bootstrapping.cgname,
      "dns-primary"        = var.bootstrapping.dns-primary,
      "dns-secondary"      = var.bootstrapping.dns-secondary,
      "vm-auth-key"        = var.bootstrapping.vm-auth-key,
      "plugin-op-commands" = var.bootstrapping.plugin-op-commands,
    }
  )
}

resource "aws_s3_bucket_object" "bootstrap_xml" {
  count  = false ? 0 : 1
  bucket = aws_s3_bucket.this.id
  key    = "config/bootstrap.xml"
  source = "${path.module}/bootstrap.xml"
}

resource "aws_s3_bucket_object" "av_package" {
  count  = false ? 0 : 1
  bucket = aws_s3_bucket.this.id
  key    = "content/${var.bootstrapping.antivirus}"
  source = "${path.module}/${var.bootstrapping.antivirus}"
}

resource "aws_s3_bucket_object" "app_threat_package" {
  count  = false ? 0 : 1
  bucket = aws_s3_bucket.this.id
  key    = "content/${var.bootstrapping.app_threat}"
  source = "${path.module}/${var.bootstrapping.app_threat}"
}

resource "aws_s3_bucket_object" "authcodes" {
  count  = false ? 0 : 1
  bucket = aws_s3_bucket.this.id
  key    = "license/authcodes"
  content = templatefile("${path.module}/authcodes.tmpl",
    {
      "authcodes" = var.bootstrapping.authcodes
    }
  )
}

locals {
  source_root_directory = coalesce(var.source_root_directory, "${path.root}/modules/vmseries/bootstrap/files")
}

resource "aws_s3_bucket_object" "bootstrap_files" {
  for_each = fileset(local.source_root_directory, "**")
  bucket = aws_s3_bucket.this.id
  key    = each.value
  source = "${local.source_root_directory}/${each.value}"
}

resource "aws_iam_role" "this" {
  name = "${var.prefix}${random_id.bucket_id.hex}"

//  tags               = var.global_tags
  assume_role_policy = <<EOF
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Effect": "Allow",
      "Principal": {
      "Service": "ec2.amazonaws.com"
    },
      "Action": "sts:AssumeRole"
    }
  ]
}
EOF
}

resource "aws_iam_role_policy" "bootstrap" {
  name   = "${var.prefix}${random_id.bucket_id.hex}"
  role   = aws_iam_role.this.id
  policy = <<EOF
{
  "Version" : "2012-10-17",
  "Statement": [
    {
      "Effect": "Allow",
      "Action": "s3:ListBucket",
      "Resource": "arn:aws:s3:::${aws_s3_bucket.this.bucket}"
    },
    {
    "Effect": "Allow",
    "Action": "s3:GetObject",
    "Resource": "arn:aws:s3:::${aws_s3_bucket.this.bucket}/*"
    },
    {
    "Effect": "Allow",
    "Action": [
      "cloudwatch:PutMetricData"
      ],
    "Resource": [
      "*"
      ]
    }
  ]
}
EOF
}

resource "aws_iam_instance_profile" "this" {
  name = coalesce(var.iam_instance_profile_name, "${var.prefix}${random_id.bucket_id.hex}")
  role = aws_iam_role.this.name
  path = "/"
}
