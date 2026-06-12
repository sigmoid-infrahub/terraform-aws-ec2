resource "aws_iam_role" "ssm_role" {
  count = local.needs_iam_profile ? 1 : 0

  name_prefix = "ec2-ssm-"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Principal = {
          Service = "ec2.amazonaws.com"
        }
        Action = "sts:AssumeRole"
      }
    ]
  })

  tags = local.resolved_tags
}

resource "aws_iam_role_policy_attachment" "ssm_core" {
  count      = var.enable_ssm && local.needs_iam_profile ? 1 : 0
  role       = aws_iam_role.ssm_role[0].name
  policy_arn = "arn:aws:iam::aws:policy/AmazonSSMManagedInstanceCore"
}

resource "aws_iam_role_policy_attachment" "cloudwatch_agent" {
  count      = local.logging_enabled ? 1 : 0
  role       = aws_iam_role.ssm_role[0].name
  policy_arn = "arn:aws:iam::aws:policy/CloudWatchAgentServerPolicy"
}

resource "aws_iam_instance_profile" "ssm_profile" {
  count = local.needs_iam_profile ? 1 : 0

  name_prefix = "ec2-ssm-"
  role        = aws_iam_role.ssm_role[0].name
}

resource "aws_cloudwatch_log_group" "app_logs" {
  count = local.logging_enabled ? 1 : 0

  name              = local.log_group_name
  retention_in_days = var.log_retention_in_days
  kms_key_id        = local.has_root_volume_kms_key ? var.root_volume_kms_key_id : null

  tags = local.resolved_tags
}

resource "aws_security_group" "this" {
  count = var.create_security_group ? 1 : 0

  name        = "${local.instance_name}-ec2-sg"
  description = "Security group for EC2 ${local.instance_name}"
  vpc_id      = var.vpc_id

  dynamic "ingress" {
    for_each = var.ingress_rules
    content {
      from_port       = ingress.value.from_port
      to_port         = ingress.value.to_port
      protocol        = ingress.value.protocol
      cidr_blocks     = ingress.value.cidr_blocks
      security_groups = ingress.value.source_security_group_ids
      description     = ingress.value.description
    }
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = local.resolved_tags
}

resource "aws_instance" "this" {
  count = var.enable_asg ? 0 : 1

  ami           = var.ami
  instance_type = var.instance_type
  subnet_id     = var.subnet_id

  key_name  = var.key_name
  user_data = local.composed_user_data

  vpc_security_group_ids = local.resolved_security_group_ids
  iam_instance_profile   = local.iam_instance_profile_name

  monitoring              = var.detailed_monitoring
  disable_api_termination = var.disable_api_termination
  disable_api_stop        = var.disable_api_stop
  ebs_optimized           = var.ebs_optimized

  metadata_options {
    http_tokens                 = var.metadata_http_tokens
    http_put_response_hop_limit = var.metadata_http_put_response_hop_limit
    http_endpoint               = var.metadata_http_endpoint
    instance_metadata_tags      = var.metadata_instance_metadata_tags
  }

  root_block_device {
    volume_size           = var.root_volume_size
    volume_type           = var.root_volume_type
    encrypted             = var.root_volume_encrypted
    kms_key_id            = local.has_root_volume_kms_key ? var.root_volume_kms_key_id : null
    delete_on_termination = true
  }

  tags = local.resolved_tags
}

resource "aws_lb_target_group_attachment" "this" {
  count = var.enable_asg ? 0 : length(var.target_group_arns)

  target_group_arn = var.target_group_arns[count.index]
  target_id        = aws_instance.this[0].id
}

resource "aws_launch_template" "this" {
  count = var.enable_asg ? 1 : 0

  name_prefix   = "${local.instance_name}-"
  image_id      = var.ami
  instance_type = var.instance_type

  key_name  = var.key_name
  user_data = local.composed_user_data != null ? base64encode(local.composed_user_data) : null

  disable_api_termination = var.disable_api_termination
  disable_api_stop        = var.disable_api_stop
  ebs_optimized           = var.ebs_optimized

  vpc_security_group_ids = local.resolved_security_group_ids

  metadata_options {
    http_tokens                 = var.metadata_http_tokens
    http_put_response_hop_limit = var.metadata_http_put_response_hop_limit
    http_endpoint               = var.metadata_http_endpoint
    instance_metadata_tags      = var.metadata_instance_metadata_tags
  }

  block_device_mappings {
    device_name = var.root_device_name

    ebs {
      volume_size           = var.root_volume_size
      volume_type           = var.root_volume_type
      encrypted             = var.root_volume_encrypted
      kms_key_id            = local.has_root_volume_kms_key ? var.root_volume_kms_key_id : null
      delete_on_termination = true
    }
  }

  monitoring {
    enabled = var.detailed_monitoring
  }

  dynamic "iam_instance_profile" {
    for_each = local.needs_iam_profile ? [1] : []
    content {
      name = aws_iam_instance_profile.ssm_profile[0].name
    }
  }

  tag_specifications {
    resource_type = "instance"
    tags          = local.resolved_tags
  }

  tags = local.resolved_tags
}

resource "aws_autoscaling_group" "this" {
  count = var.enable_asg ? 1 : 0

  name_prefix = "${lookup(local.resolved_tags, "Name", "ec2")}-"

  min_size         = var.asg_min_size
  max_size         = var.asg_max_size
  desired_capacity = var.asg_desired_capacity

  health_check_type         = var.asg_health_check_type
  health_check_grace_period = var.asg_health_check_grace_period

  vpc_zone_identifier = var.asg_subnet_ids
  target_group_arns   = var.asg_target_group_arns

  launch_template {
    id      = aws_launch_template.this[0].id
    version = "$Latest"
  }

  dynamic "tag" {
    for_each = local.resolved_tags
    content {
      key                 = tag.key
      value               = tag.value
      propagate_at_launch = true
    }
  }

  lifecycle {
    ignore_changes = [desired_capacity]
  }
}
