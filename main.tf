resource "aws_iam_role" "ssm_role" {
  count = var.enable_ssm ? 1 : 0

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
  count      = var.enable_ssm ? 1 : 0
  role       = aws_iam_role.ssm_role[0].name
  policy_arn = "arn:aws:iam::aws:policy/AmazonSSMManagedInstanceCore"
}

resource "aws_iam_instance_profile" "ssm_profile" {
  count = var.enable_ssm ? 1 : 0

  name_prefix = "ec2-ssm-"
  role        = aws_iam_role.ssm_role[0].name
}

resource "aws_instance" "this" {
  count = var.enable_asg ? 0 : 1

  ami           = var.ami
  instance_type = var.instance_type
  subnet_id     = var.subnet_id

  key_name  = var.key_name
  user_data = var.user_data

  vpc_security_group_ids = var.security_group_ids
  iam_instance_profile   = var.enable_ssm ? aws_iam_instance_profile.ssm_profile[0].name : null

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

resource "aws_launch_template" "this" {
  count = var.enable_asg ? 1 : 0

  name_prefix   = "${lookup(local.resolved_tags, "Name", "ec2")}-"
  image_id      = var.ami
  instance_type = var.instance_type

  key_name  = var.key_name
  user_data = var.user_data != null ? base64encode(var.user_data) : null

  disable_api_termination = var.disable_api_termination
  disable_api_stop        = var.disable_api_stop
  ebs_optimized           = var.ebs_optimized

  vpc_security_group_ids = var.security_group_ids

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
    for_each = var.enable_ssm ? [1] : []
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
