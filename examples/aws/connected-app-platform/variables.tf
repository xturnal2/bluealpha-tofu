variable "aws_region" {
  description = "AWS region for the connected architecture."
  type        = string
  default     = "us-east-1"
}

variable "project_name" {
  description = "Short project identifier used across every composed stack."
  type        = string
  validation {
    condition     = can(regex("^[a-z][a-z0-9-]{1,18}[a-z0-9]$", var.project_name))
    error_message = "project_name must be 3-20 lowercase letters, numbers, or hyphens."
  }
}

variable "environment" {
  description = "Deployment environment."
  type        = string
  default     = "dev"
  validation {
    condition     = can(regex("^[a-z][a-z0-9-]{1,14}[a-z0-9]$", var.environment))
    error_message = "environment must be 3-16 lowercase letters, numbers, or hyphens."
  }
}

variable "container_image" {
  description = "Application image URI, preferably pinned to an immutable digest."
  type        = string
}

variable "container_port" {
  description = "HTTP port exposed by the application container."
  type        = number
  default     = 8080
  validation {
    condition     = var.container_port >= 1 && var.container_port <= 65535
    error_message = "container_port must be from 1 through 65535."
  }
}

variable "health_check_path" {
  description = "Application Load Balancer health-check path."
  type        = string
  default     = "/health"
  validation {
    condition     = startswith(var.health_check_path, "/")
    error_message = "health_check_path must start with /."
  }
}

variable "vpc_cidr" {
  description = "CIDR for the generated VPC."
  type        = string
  default     = "10.0.0.0/16"
  validation {
    condition     = can(cidrnetmask(var.vpc_cidr)) && can(cidrsubnet(var.vpc_cidr, 4, 0))
    error_message = "vpc_cidr must be a valid IPv4 CIDR large enough for generated subnets."
  }
}

variable "availability_zone_count" {
  description = "Number of availability zones used by public and private subnets."
  type        = number
  default     = 2
  validation {
    condition     = contains([2, 3], var.availability_zone_count)
    error_message = "availability_zone_count must be 2 or 3."
  }
}

variable "enable_nat_gateway" {
  description = "Create NAT for private ECS task egress. Disable only when equivalent VPC endpoints/egress exist."
  type        = bool
  default     = false
}

variable "single_nat_gateway" {
  description = "Share one NAT gateway across zones. Lower cost but introduces a zone dependency."
  type        = bool
  default     = true
}

variable "enable_flow_logs" {
  description = "Send VPC flow logs to CloudWatch Logs."
  type        = bool
  default     = false
}

variable "internal_load_balancer" {
  description = "Keep the application load balancer internal. False makes it internet-facing."
  type        = bool
  default     = true
}

variable "allowed_ingress_cidrs" {
  description = "CIDRs allowed to reach the load balancer. Empty denies CIDR ingress."
  type        = set(string)
  default     = []
  validation {
    condition     = alltrue([for cidr in var.allowed_ingress_cidrs : can(cidrnetmask(cidr))])
    error_message = "allowed_ingress_cidrs must contain valid IPv4 CIDRs."
  }
}

variable "certificate_arn" {
  description = "ACM certificate ARN for HTTPS. Required for internet-facing deployments."
  type        = string
  default     = null
}

variable "desired_count" {
  description = "Initial ECS task count."
  type        = number
  default     = 1
  validation {
    condition     = var.desired_count >= 1 && floor(var.desired_count) == var.desired_count
    error_message = "desired_count must be a positive integer."
  }
}

variable "autoscaling_max_capacity" {
  description = "Maximum ECS task count under CPU autoscaling."
  type        = number
  default     = 4
  validation {
    condition     = var.autoscaling_max_capacity >= 1 && floor(var.autoscaling_max_capacity) == var.autoscaling_max_capacity
    error_message = "autoscaling_max_capacity must be a positive integer."
  }
}

variable "database_name" {
  description = "Initial PostgreSQL database name."
  type        = string
  default     = "app"
}

variable "database_instance_class" {
  description = "RDS PostgreSQL instance class."
  type        = string
  default     = "db.t4g.micro"
}

variable "database_multi_az" {
  description = "Create a synchronous RDS standby in another availability zone."
  type        = bool
  default     = false
}

variable "database_backup_retention_days" {
  description = "Automated RDS backup retention."
  type        = number
  default     = 7
  validation {
    condition     = var.database_backup_retention_days >= 1 && var.database_backup_retention_days <= 35
    error_message = "database_backup_retention_days must be from 1 through 35."
  }
}

variable "database_deletion_protection" {
  description = "Protect RDS from deletion. Disable and apply before intentional destroy."
  type        = bool
  default     = true
}

variable "database_skip_final_snapshot" {
  description = "Skip the RDS final snapshot during destroy. False is safer."
  type        = bool
  default     = false
}

variable "dynamodb_deletion_protection" {
  description = "Protect DynamoDB from deletion. Disable and apply before intentional destroy."
  type        = bool
  default     = true
}

variable "dynamodb_point_in_time_recovery" {
  description = "Enable continuous DynamoDB recovery points."
  type        = bool
  default     = true
}

variable "queue_fifo" {
  description = "Use a FIFO SQS queue. The application must then send MessageGroupId values."
  type        = bool
  default     = false
}

variable "log_retention_days" {
  description = "CloudWatch log retention for ECS and VPC flow logs."
  type        = number
  default     = 30
  validation {
    condition     = contains([1, 3, 5, 7, 14, 30, 60, 90, 120, 150, 180, 365, 400, 545, 731, 1096, 1827, 2192, 2557, 2922, 3288, 3653], var.log_retention_days)
    error_message = "log_retention_days must be supported by CloudWatch Logs."
  }
}

variable "tags" {
  description = "Additional tags passed to every composed stack."
  type        = map(string)
  default     = {}
}
