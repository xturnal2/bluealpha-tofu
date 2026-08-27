aws_region   = "us-east-1"
project_name = "example-app"
environment  = "dev"

trusted_service_principals   = ["ecs-tasks.amazonaws.com"]
max_session_duration_seconds = 3600
force_detach_policies        = false

# Attach only policies the workload genuinely needs.
managed_policy_arns = []

# Inline policies are JSON strings. Keep resources narrowly scoped.
inline_policies = {
  read_configuration = <<-JSON
  {
    "Version": "2012-10-17",
    "Statement": [{
      "Effect": "Allow",
      "Action": ["ssm:GetParameter"],
      "Resource": "arn:aws:ssm:us-east-1:123456789012:parameter/example-app/dev/*"
    }]
  }
  JSON
}

tags = {
  Owner      = "platform-team"
  CostCenter = "shared-services"
}
