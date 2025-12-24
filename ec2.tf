data "aws_vpc" "default" {
  default = true
}

module "label" {
  source = "git::https://github.com/cloudposse/terraform-terraform-label.git?ref=main"
  
  name = var.name
  tags = var.tags
}

data "aws_subnets" "default" {
  filter {
    name   = "vpc-id"
    values = [var.vpc_id != "" ? var.vpc_id : data.aws_vpc.default.id]
  }
}

locals {
  vpc_id             = var.vpc_id != "" ? var.vpc_id : data.aws_vpc.default.id
  subnet_id          = var.subnet_id != "" ? var.subnet_id : data.aws_subnets.default.ids[0]
  backup_bucket_name = var.backup_bucket_name
}

data "aws_ami" "amazon-linux-2" {
  most_recent = true

  owners = ["amazon"]
  filter {
    name   = "name"
    values = ["amzn2-ami-hvm*"]
  }
}

// Security group for our instance - allows minecraft port only
module "ec2_security_group" {
  source = "git@github.com:terraform-aws-modules/terraform-aws-security-group.git?ref=master"

  name        = "${var.name}-ec2"
  description = "Allow TCP ${var.mc_port}"
  vpc_id      = local.vpc_id

  ingress_with_cidr_blocks = [
    {
      from_port   = var.mc_port
      to_port     = var.mc_port
      protocol    = "tcp"
      description = "Minecraft server port"
      cidr_blocks = "0.0.0.0/0" // allow all IPs to connect to Minecraft port
    },
    {
      from_port   = 22
      to_port     = 22
      protocol    = "tcp"
      description = "SSH access"
      cidr_blocks = join(",", var.allowed_cidrs)
    }
  ]
  egress_rules = ["all-all"]

  tags = module.label.tags
}

resource "aws_iam_role" "allow_s3" {
  name   = "${module.label.id}-allow-ec2-to-s3"
  assume_role_policy = <<EOF
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Action": "sts:AssumeRole",
      "Principal": {
        "Service": "ec2.amazonaws.com"
      },
      "Effect": "Allow",
      "Sid": ""
    }
  ]
}
EOF
}

resource "aws_iam_instance_profile" "mc" {
  name = "${module.label.id}-instance-profile"
  role = aws_iam_role.allow_s3.name
}

resource "aws_iam_role_policy" "mc_allow_ec2_to_s3" {
  name   = "${module.label.id}-allow-ec2-to-s3"
  role   = aws_iam_role.allow_s3.id
  policy = <<EOF
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Effect": "Allow",
      "Action": ["s3:ListBucket"],
      "Resource": ["arn:aws:s3:::${var.backup_bucket_name}"]
    },
    {
      "Effect": "Allow",
      "Action": [
        "s3:PutObject",
        "s3:GetObject",
        "s3:DeleteObject"
      ],
      "Resource": ["arn:aws:s3:::${var.backup_bucket_name}/*"]
    }
  ]
}
EOF
}

resource "aws_iam_role_policy_attachment" "cloudwatch" {
  role       = aws_iam_role.allow_s3.name
  policy_arn = "arn:aws:iam::aws:policy/CloudWatchAgentServerPolicy"
}

# Create log groups
resource "aws_cloudwatch_log_group" "minecraft_server" {
  name              = "/minecraft/server"
  retention_in_days = 7
}

resource "aws_cloudwatch_log_group" "cloud_init" {
  name              = "/minecraft/cloud-init"
  retention_in_days = 7
}

resource "aws_iam_role_policy_attachment" "ssm" {
  role       = aws_iam_role.allow_s3.name
  policy_arn = "arn:aws:iam::aws:policy/AmazonSSMManagedInstanceCore"
}

module "ec2_minecraft" {
  source = "git::https://github.com/terraform-aws-modules/terraform-aws-ec2-instance.git?ref=master"
  name   = "${var.name}-public"

  # instance
  ami                  = data.aws_ami.amazon-linux-2.id
  instance_type        = var.instance_type
  iam_instance_profile = aws_iam_instance_profile.mc.id
  user_data = templatefile("scripts/minecraft_deploy.sh", {
    mc_root_dir        = var.mc_root_dir
    backup_bucket_name = var.backup_bucket_name
    minecraft_ram      = var.minecraft_ram
    backup_frequency   = var.backup_frequency
    server_properties  = file("${path.module}/config/server.properties")
    ops_json          = file("${path.module}/config/ops.json")
})

  # network
  subnet_id                   = local.subnet_id
  vpc_security_group_ids      = [module.ec2_security_group.security_group_id]
  associate_public_ip_address = var.associate_public_ip_address

  tags = module.label.tags
}

// associate Elastic IP
resource "aws_eip" "mc_eip" {
  instance  = module.ec2_minecraft.id
  domain    = "vpc"
}
