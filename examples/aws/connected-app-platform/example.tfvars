aws_region   = "us-east-1"
project_name = "example"
environment  = "dev"

# Replace with an image that listens on container_port and serves health_check_path.
container_image   = "123456789012.dkr.ecr.us-east-1.amazonaws.com/example-api@sha256:replace-me"
container_port    = 8080
health_check_path = "/health"

vpc_cidr                = "10.0.0.0/16"
availability_zone_count = 2
enable_nat_gateway      = true
single_nat_gateway      = true

# Internal by default. This example permits clients already inside the VPC.
internal_load_balancer = true
allowed_ingress_cidrs  = ["10.0.0.0/16"]

desired_count            = 1
autoscaling_max_capacity = 4

database_instance_class        = "db.t4g.micro"
database_multi_az              = false
database_backup_retention_days = 7
database_deletion_protection   = true
database_skip_final_snapshot   = false

dynamodb_deletion_protection    = true
dynamodb_point_in_time_recovery = true

queue_fifo         = false
log_retention_days = 30

tags = {
  Owner      = "platform-team"
  CostCenter = "engineering"
}
