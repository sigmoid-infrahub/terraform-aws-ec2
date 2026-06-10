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

variable "key_name" {
  type        = string
  description = "Name of an existing EC2 key pair for SSH access"
  default     = null
}

variable "user_data" {
  type        = string
  description = "User data script to run on instance launch"
  default     = null
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

variable "metadata_http_tokens" {
  type        = string
  description = "Whether IMDS requires session tokens. Use required to enforce IMDSv2."
  default     = "required"

  validation {
    condition     = contains(["required", "optional"], var.metadata_http_tokens)
    error_message = "metadata_http_tokens must be required or optional."
  }
}

variable "metadata_http_put_response_hop_limit" {
  type        = number
  description = "Desired HTTP PUT response hop limit for instance metadata requests."
  default     = 2

  validation {
    condition     = var.metadata_http_put_response_hop_limit >= 1 && var.metadata_http_put_response_hop_limit <= 64
    error_message = "metadata_http_put_response_hop_limit must be between 1 and 64."
  }
}

variable "metadata_http_endpoint" {
  type        = string
  description = "Whether the instance metadata service endpoint is enabled."
  default     = "enabled"

  validation {
    condition     = contains(["enabled", "disabled"], var.metadata_http_endpoint)
    error_message = "metadata_http_endpoint must be enabled or disabled."
  }
}

variable "metadata_instance_metadata_tags" {
  type        = string
  description = "Whether instance tags are available from the metadata service."
  default     = "enabled"

  validation {
    condition     = contains(["enabled", "disabled"], var.metadata_instance_metadata_tags)
    error_message = "metadata_instance_metadata_tags must be enabled or disabled."
  }
}

variable "root_volume_encrypted" {
  type        = bool
  description = "Encrypt the EC2 root volume."
  default     = true
}

variable "root_volume_kms_key_id" {
  type        = string
  description = "KMS key ID or ARN used to encrypt the EC2 root volume. When empty, the account default EBS KMS key is used."
  default     = ""
}

variable "root_volume_size" {
  type        = number
  description = "Root volume size in GiB."
  default     = 20

  validation {
    condition     = var.root_volume_size > 0
    error_message = "root_volume_size must be greater than 0."
  }
}

variable "root_volume_type" {
  type        = string
  description = "Root volume EBS type."
  default     = "gp3"

  validation {
    condition     = contains(["standard", "gp2", "gp3", "io1", "io2", "sc1", "st1"], var.root_volume_type)
    error_message = "root_volume_type must be a valid EBS volume type."
  }
}

variable "root_device_name" {
  type        = string
  description = "Root device name used in launch template block device mappings. Must match the selected AMI root device name."
  default     = "/dev/xvda"
}

variable "detailed_monitoring" {
  type        = bool
  description = "Enable detailed CloudWatch monitoring for EC2."
  default     = true
}

variable "disable_api_termination" {
  type        = bool
  description = "Enable EC2 API termination protection."
  default     = true
}

variable "disable_api_stop" {
  type        = bool
  description = "Enable EC2 API stop protection."
  default     = false
}

variable "ebs_optimized" {
  type        = bool
  description = "Enable EBS optimization for the EC2 instance or launch template."
  default     = true
}

variable "log_paths" {
  type        = list(string)
  description = "Log file paths to ship to CloudWatch via the CloudWatch agent. Supports glob patterns (e.g. /var/log/app/*.log). When non-empty, the agent is installed and configured and a log group is created."
  default     = []
}

variable "log_retention_in_days" {
  type        = number
  description = "Retention in days for the EC2 application log group created when log_paths is set."
  default     = 30
}

# ====================================
# Sigmoid Tags Configuration
# ====================================

variable "enable_asg" {
  type        = bool
  description = "Create ASG + Launch Template instead of standalone EC2 instance"
  default     = false
}

variable "asg_min_size" {
  type        = number
  description = "ASG minimum size"
  default     = 1
}

variable "asg_max_size" {
  type        = number
  description = "ASG maximum size"
  default     = 1
}

variable "asg_desired_capacity" {
  type        = number
  description = "ASG desired capacity"
  default     = 1
}

variable "asg_health_check_type" {
  type        = string
  description = "ASG health check type (EC2 or ELB)"
  default     = "EC2"

  validation {
    condition     = contains(["EC2", "ELB"], var.asg_health_check_type)
    error_message = "asg_health_check_type must be EC2 or ELB."
  }
}

variable "asg_health_check_grace_period" {
  type        = number
  description = "ASG health check grace period in seconds"
  default     = 300
}

variable "asg_target_group_arns" {
  type        = list(string)
  description = "Target group ARNs to attach to the ASG"
  default     = []
}

variable "asg_subnet_ids" {
  type        = list(string)
  description = "Subnet IDs for ASG (vpc_zone_identifier). Required when enable_asg = true."
  default     = []
}

# ====================================
# Sigmoid Tags Configuration
# ====================================

variable "sigmoid_environment" {
  description = "Sigmoid environment identifier for cost allocation"
  type        = string
  default     = ""
}

variable "sigmoid_project" {
  description = "Sigmoid project identifier for cost allocation"
  type        = string
  default     = ""
}

variable "sigmoid_team" {
  description = "Sigmoid team identifier for cost allocation"
  type        = string
  default     = ""
}
