output "instance_id" {
  description = "EC2 instance ID"
  value       = aws_instance.this.id
}

output "private_ip" {
  description = "EC2 private IP"
  value       = aws_instance.this.private_ip
}

output "iam_instance_profile_arn" {
  description = "IAM instance profile ARN for SSM access (null if SSM disabled)"
  value       = var.enable_ssm ? aws_iam_instance_profile.ssm_profile[0].arn : null
}

output "module" {
  description = "Full module outputs"
  value = {
    instance_id              = aws_instance.this.id
    private_ip               = aws_instance.this.private_ip
    iam_instance_profile_arn = var.enable_ssm ? aws_iam_instance_profile.ssm_profile[0].arn : null
  }
}
