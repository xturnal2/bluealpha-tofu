project_name = "acme-app"
environment  = "dev"
aws_region   = "us-east-1"

vpc_id     = "vpc-0123456789abcdef0"
subnet_ids = ["subnet-0123456789abcdef2", "subnet-0123456789abcdef3"]

# Prefer application security group references over broad CIDR access.
allowed_security_group_ids = ["sg-0123456789abcdef0"]
allowed_cidrs              = []

database_name   = "app"
master_username = "dbadmin"
instance_class  = "db.t4g.micro"

allocated_storage_gib     = 20
max_allocated_storage_gib = 100
multi_az                  = false
publicly_accessible       = false

manage_master_user_password = true
backup_retention_days       = 7
deletion_protection         = true
skip_final_snapshot         = false

enable_performance_insights = false
monitoring_interval_seconds = 0

tags = {
  Owner      = "platform-team"
  CostCenter = "data"
}
