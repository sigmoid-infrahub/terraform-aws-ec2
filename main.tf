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
  count       = var.enable_ssm ? 1 : 0
  role        = aws_iam_role.ssm_role[0].name
  policy_arn  = "arn:aws:iam::aws:policy/AmazonSSMManagedInstanceCore"
}

resource "aws_iam_instance_profile" "ssm_profile" {
  count = var.enable_ssm ? 1 : 0

  name_prefix = "ec2-ssm-"
  role        = aws_iam_role.ssm_role[0].name
}

resource "aws_instance" "this" {
  ami           = var.ami
  instance_type = var.instance_type
  subnet_id     = var.subnet_id

  vpc_security_group_ids = var.security_group_ids
  iam_instance_profile   = var.enable_ssm ? aws_iam_instance_profile.ssm_profile[0].name : null

  tags = local.resolved_tags
}
