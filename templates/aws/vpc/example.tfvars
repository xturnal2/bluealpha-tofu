project_name = "acme-platform"
environment  = "dev"
aws_region   = "us-east-1"
vpc_cidr     = "10.20.0.0/16"

# Cost flags: enable only when private workloads need outbound internet.
enable_nat_gateway = false
single_nat_gateway = false

# Security flag: assign public IP addresses only when the workload requires it.
map_public_ip_on_launch = false

# Logging is recommended for production and incurs CloudWatch charges.
enable_flow_logs = false

tags = {
  Owner      = "platform-team"
  CostCenter = "shared-services"
}
