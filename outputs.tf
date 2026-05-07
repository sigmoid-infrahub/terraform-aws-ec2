output "instance_id" {
  description = "EC2 instance ID"
  value       = var.enable_asg ? null : aws_instance.this[0].id
}

output "instance_arn" {
  description = "EC2 instance ARN"
  value       = var.enable_asg ? null : aws_instance.this[0].arn
}

output "private_ip" {
  description = "EC2 private IP"
  value       = var.enable_asg ? null : aws_instance.this[0].private_ip
}

output "public_ip" {
  description = "EC2 public IP"
  value       = var.enable_asg ? null : aws_instance.this[0].public_ip
}

output "primary_network_interface_id" {
  description = "EC2 primary network interface ID"
  value       = var.enable_asg ? null : aws_instance.this[0].primary_network_interface_id
}

output "iam_instance_profile_arn" {
  description = "IAM instance profile ARN for SSM access (null if SSM disabled)"
  value       = var.enable_ssm ? aws_iam_instance_profile.ssm_profile[0].arn : null
}

output "asg_id" {
  description = "Auto Scaling Group ID"
  value       = var.enable_asg ? aws_autoscaling_group.this[0].id : ""
}

output "asg_arn" {
  description = "Auto Scaling Group ARN"
  value       = var.enable_asg ? aws_autoscaling_group.this[0].arn : ""
}

output "asg_name" {
  description = "Auto Scaling Group name"
  value       = var.enable_asg ? aws_autoscaling_group.this[0].name : ""
}

output "launch_template_id" {
  description = "Launch Template ID"
  value       = var.enable_asg ? aws_launch_template.this[0].id : ""
}

output "module" {
  description = "Full module outputs"
  value = {
    instance_id                  = var.enable_asg ? null : aws_instance.this[0].id
    instance_arn                 = var.enable_asg ? null : aws_instance.this[0].arn
    private_ip                   = var.enable_asg ? null : aws_instance.this[0].private_ip
    public_ip                    = var.enable_asg ? null : aws_instance.this[0].public_ip
    primary_network_interface_id = var.enable_asg ? null : aws_instance.this[0].primary_network_interface_id
    iam_instance_profile_arn     = var.enable_ssm ? aws_iam_instance_profile.ssm_profile[0].arn : null
    asg_id                       = var.enable_asg ? aws_autoscaling_group.this[0].id : ""
    asg_arn                      = var.enable_asg ? aws_autoscaling_group.this[0].arn : ""
    asg_name                     = var.enable_asg ? aws_autoscaling_group.this[0].name : ""
    launch_template_id           = var.enable_asg ? aws_launch_template.this[0].id : ""
  }
}
