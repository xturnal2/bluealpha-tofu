aws_region   = "us-east-1"
project_name = "example-app"
environment  = "dev"

namespace   = "AWS/ApplicationELB"
metric_name = "HTTPCode_Target_5XX_Count"
statistic   = "Sum"
threshold   = 5

period_seconds      = 300
evaluation_periods  = 3
datapoints_to_alarm = 2
treat_missing_data  = "notBreaching"

dimensions = {
  LoadBalancer = "app/example/0000000000000000"
}

# alarm_action_arns = ["arn:aws:sns:us-east-1:123456789012:platform-alerts"]
