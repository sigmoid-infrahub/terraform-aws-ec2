locals {
  sigmoid_tags = merge(
    var.sigmoid_environment != "" ? { "sigmoid:environment" = var.sigmoid_environment } : {},
    var.sigmoid_project != "" ? { "sigmoid:project" = var.sigmoid_project } : {},
    var.sigmoid_team != "" ? { "sigmoid:team" = var.sigmoid_team } : {},
  )


  resolved_tags = merge({
    ManagedBy = "sigmoid"
  }, var.tags, local.sigmoid_tags)

  has_root_volume_kms_key = length(trimspace(var.root_volume_kms_key_id)) > 0

  instance_name             = lookup(local.resolved_tags, "Name", "ec2")
  logging_enabled           = length(var.log_paths) > 0
  log_group_name            = "/sigmoid/ec2/${local.instance_name}"
  needs_iam_profile         = var.enable_ssm || local.logging_enabled
  iam_instance_profile_name = local.needs_iam_profile ? aws_iam_instance_profile.ssm_profile[0].name : null

  cw_agent_collect_files = [
    for path in var.log_paths : {
      file_path       = path
      log_group_name  = local.log_group_name
      log_stream_name = "{instance_id}_${replace(trim(path, "/"), "/[^a-zA-Z0-9_.-]/", "_")}"
    }
  ]

  cw_agent_config = jsonencode({
    logs = {
      logs_collected = {
        files = {
          collect_list = local.cw_agent_collect_files
        }
      }
    }
  })

  # User data that installs/configures the CloudWatch agent, prepended to any
  # user-provided script so existing startup behavior is preserved.
  cw_agent_user_data = <<-AGENT
    #!/bin/bash
    set -euo pipefail
    if command -v dnf >/dev/null 2>&1; then
      dnf install -y amazon-cloudwatch-agent || yum install -y amazon-cloudwatch-agent
    elif command -v yum >/dev/null 2>&1; then
      yum install -y amazon-cloudwatch-agent
    elif command -v apt-get >/dev/null 2>&1; then
      apt-get update -y
      apt-get install -y amazon-cloudwatch-agent || (curl -fsSL -o /tmp/cwagent.deb https://s3.amazonaws.com/amazoncloudwatch-agent/ubuntu/$(dpkg --print-architecture)/latest/amazon-cloudwatch-agent.deb && dpkg -i /tmp/cwagent.deb)
    fi
    mkdir -p /opt/aws/amazon-cloudwatch-agent/etc
    cat > /opt/aws/amazon-cloudwatch-agent/etc/sigmoid-agent.json <<'CWCONFIG'
    ${local.cw_agent_config}
    CWCONFIG
    /opt/aws/amazon-cloudwatch-agent/bin/amazon-cloudwatch-agent-ctl -a fetch-config -m ec2 -s -c file:/opt/aws/amazon-cloudwatch-agent/etc/sigmoid-agent.json
  AGENT

  composed_user_data = local.logging_enabled ? (
    var.user_data != null ? "${local.cw_agent_user_data}\n${var.user_data}" : local.cw_agent_user_data
  ) : var.user_data
}
