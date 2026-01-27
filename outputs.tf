output "instance_id" {
  description = "EC2 instance ID"
  value       = aws_instance.this.id
}

output "private_ip" {
  description = "EC2 private IP"
  value       = aws_instance.this.private_ip
}

output "module" {
  description = "Full module outputs"
  value = {
    instance_id = aws_instance.this.id
    private_ip  = aws_instance.this.private_ip
  }
}
