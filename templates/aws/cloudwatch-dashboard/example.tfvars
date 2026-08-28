aws_region   = "us-east-1"
project_name = "example-app"
environment  = "dev"

text_widgets = {
  heading = {
    x        = 0
    y        = 0
    markdown = "# Example application\nOwner: platform-team | Runbook: replace-me"
  }
}

metric_widgets = {
  alb_errors = {
    title       = "ALB target 5XX responses"
    namespace   = "AWS/ApplicationELB"
    metric_name = "HTTPCode_Target_5XX_Count"
    statistic   = "Sum"
    x           = 0
    y           = 3
    dimensions = {
      LoadBalancer = "app/example/0000000000000000"
    }
    horizontal_annotations = [{ label = "investigate", value = 5 }]
  }
}
