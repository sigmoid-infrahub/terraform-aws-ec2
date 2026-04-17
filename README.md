# Module: EC2

This module launches a single Amazon EC2 instance with specified AMI, instance type, and networking configuration.

## Features
- Launch EC2 instance with custom AMI
- Security group and Subnet configuration
- Tagging support for resource management
- Validation for AMI ID format

## Usage
```hcl
module "ec2" {
  source = "../../terraform-modules/terraform-aws-ec2"

  ami           = "ami-0c55b159cbfafe1f0"
  instance_type = "t3.micro"
  subnet_id     = "subnet-12345678"
}
```

## Inputs
| Name | Type | Default | Description |
|------|------|---------|-------------|
| `ami` | `string` | n/a | AMI ID |
| `instance_type` | `string` | n/a | EC2 instance type |
| `subnet_id` | `string` | n/a | Subnet ID |
| `security_group_ids` | `list(string)` | `[]` | Security group IDs |
| `tags` | `map(string)` | `{}` | Tags to apply to the instance |

## Outputs
| Name | Description |
|------|-------------|
| `instance_id` | EC2 instance ID |
| `private_ip` | EC2 private IP |
| `module` | Full module outputs |

## Environment Variables
None

## Notes
- The `ami` must start with `ami-`.
- Ensure the selected instance type is available in the target subnet's availability zone.
