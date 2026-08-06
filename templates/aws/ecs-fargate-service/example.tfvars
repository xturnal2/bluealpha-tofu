project_name = "acme-api"
environment  = "dev"
aws_region   = "us-east-1"

vpc_id                   = "vpc-0123456789abcdef0"
load_balancer_subnet_ids = ["subnet-0123456789abcdef0", "subnet-0123456789abcdef1"]
task_subnet_ids          = ["subnet-0123456789abcdef2", "subnet-0123456789abcdef3"]

container_image = "public.ecr.aws/nginx/nginx:stable"
container_port  = 80
cpu             = 256
memory          = 512
desired_count   = 1

# Secure default: internal and unreachable until an allowed source is supplied.
internal_load_balancer = true
allowed_ingress_cidrs  = ["10.0.0.0/8"]
assign_public_ip       = false

enable_autoscaling        = true
autoscaling_min_capacity  = 1
autoscaling_max_capacity  = 4
enable_container_insights = false
use_fargate_spot          = false

environment_variables = {
  APP_ENV = "dev"
}

tags = {
  Owner      = "platform-team"
  CostCenter = "applications"
}
