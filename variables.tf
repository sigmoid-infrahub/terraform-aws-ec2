variable "ami" {
  type        = string
  description = "AMI ID"

  validation {
    condition     = can(regex("^ami-", var.ami))
    error_message = "ami must start with ami-."
  }
}

variable "instance_type" {
  type        = string
  description = "EC2 instance type"
}

variable "subnet_id" {
  type        = string
  description = "Subnet ID"
}

variable "security_group_ids" {
  type        = list(string)
  description = "Security group IDs"
  default     = []
}

variable "tags" {
  type        = map(string)
  description = "Tags to apply to the instance"
  default     = {}
}

variable "enable_ssm" {
  type        = bool
  description = "Enable SSM Session Manager support for this EC2 instance"
  default     = false
}
