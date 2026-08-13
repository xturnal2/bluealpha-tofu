variable "project_name" {
  description = "Short project identifier used in resource names and tags."
  type        = string
  validation {
    condition     = can(regex("^[a-z][a-z0-9-]{1,22}[a-z0-9]$", var.project_name))
    error_message = "project_name must be 3-24 lowercase letters, numbers, or hyphens."
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

variable "aws_region" {
  description = "AWS region for the service."
  type        = string
  default     = "us-east-1"
}

variable "vpc_id" {
  description = "VPC ID for the load balancer and service security groups."
  type        = string
}

variable "load_balancer_subnet_ids" {
  description = "At least two subnet IDs in different availability zones for the Application Load Balancer."
  type        = list(string)
  validation {
    condition     = length(distinct(var.load_balancer_subnet_ids)) >= 2
    error_message = "load_balancer_subnet_ids must contain at least two unique subnet IDs."
  }
}

variable "task_subnet_ids" {
  description = "Subnet IDs in which Fargate tasks run. Private subnets are recommended."
  type        = list(string)
  validation {
    condition     = length(distinct(var.task_subnet_ids)) >= 1
    error_message = "task_subnet_ids must contain at least one subnet ID."
  }
}

variable "additional_task_security_group_ids" {
  description = "Additional security groups attached to task ENIs for shared downstream access policies."
  type        = set(string)
  default     = []
}

variable "container_image" {
  description = "Container image URI, ideally pinned to an immutable digest or version tag."
  type        = string
}

variable "container_port" {
  description = "Port exposed by the application container."
  type        = number
  default     = 8080
  validation {
    condition     = var.container_port >= 1 && var.container_port <= 65535
    error_message = "container_port must be from 1 through 65535."
  }
}

variable "cpu" {
  description = "Fargate task CPU units."
  type        = number
  default     = 256
  validation {
    condition     = contains([256, 512, 1024, 2048, 4096, 8192, 16384], var.cpu)
    error_message = "cpu must be a supported Fargate CPU value."
  }
}

variable "memory" {
  description = "Fargate task memory in MiB. Must be compatible with cpu."
  type        = number
  default     = 512
}

variable "cpu_architecture" {
  description = "Container CPU architecture."
  type        = string
  default     = "X86_64"
  validation {
    condition     = contains(["X86_64", "ARM64"], var.cpu_architecture)
    error_message = "cpu_architecture must be X86_64 or ARM64."
  }
}

variable "desired_count" {
  description = "Initial number of running tasks."
  type        = number
  default     = 1
  validation {
    condition     = var.desired_count >= 0 && floor(var.desired_count) == var.desired_count
    error_message = "desired_count must be a non-negative integer."
  }
}

variable "use_fargate_spot" {
  description = "Run tasks on interruptible Fargate Spot capacity."
  type        = bool
  default     = false
}

variable "assign_public_ip" {
  description = "Assign public IPv4 addresses to tasks. Private tasks should use NAT or VPC endpoints for image pulls and logs."
  type        = bool
  default     = false
}

variable "internal_load_balancer" {
  description = "Create an internal load balancer. Set false for an internet-facing endpoint."
  type        = bool
  default     = true
}

variable "allowed_ingress_cidrs" {
  description = "IPv4 CIDRs allowed to reach the load balancer. Empty creates no CIDR ingress rules."
  type        = set(string)
  default     = []
  validation {
    condition     = alltrue([for cidr in var.allowed_ingress_cidrs : can(cidrnetmask(cidr))])
    error_message = "Every allowed_ingress_cidrs value must be a valid IPv4 CIDR."
  }
}

variable "allowed_ingress_security_group_ids" {
  description = "Security group IDs allowed to reach an internal load balancer."
  type        = set(string)
  default     = []
}

variable "certificate_arn" {
  description = "ACM certificate ARN for HTTPS. Null creates an HTTP listener only."
  type        = string
  default     = null
}

variable "redirect_http_to_https" {
  description = "Redirect port 80 to HTTPS when certificate_arn is set."
  type        = bool
  default     = true
}

variable "health_check_path" {
  description = "HTTP path used by the target group health check."
  type        = string
  default     = "/health"
  validation {
    condition     = startswith(var.health_check_path, "/")
    error_message = "health_check_path must start with /."
  }
}

variable "environment_variables" {
  description = "Non-sensitive environment variables passed to the container."
  type        = map(string)
  default     = {}
}

variable "secrets" {
  description = "Map of container variable names to Secrets Manager secret ARNs or SSM parameter ARNs."
  type        = map(string)
  default     = {}
}

variable "task_role_policy_statements" {
  description = "Additional least-privilege Allow statements attached to the application task role."
  type = list(object({
    sid       = optional(string, null)
    actions   = set(string)
    resources = set(string)
  }))
  default = []
  validation {
    condition = alltrue([
      for statement in var.task_role_policy_statements :
      length(statement.actions) > 0 && length(statement.resources) > 0
    ])
    error_message = "Every task role policy statement must include at least one action and resource."
  }
}

variable "log_retention_days" {
  description = "CloudWatch Logs retention period."
  type        = number
  default     = 30
  validation {
    condition     = contains([1, 3, 5, 7, 14, 30, 60, 90, 120, 150, 180, 365, 400, 545, 731, 1096, 1827, 2192, 2557, 2922, 3288, 3653], var.log_retention_days)
    error_message = "log_retention_days must be supported by CloudWatch Logs."
  }
}

variable "enable_container_insights" {
  description = "Enable ECS Container Insights metrics. Additional CloudWatch charges apply."
  type        = bool
  default     = false
}

variable "enable_execute_command" {
  description = "Enable ECS Exec and grant the task role required SSM message permissions."
  type        = bool
  default     = false
}

variable "enable_autoscaling" {
  description = "Scale task count based on average ECS CPU utilization."
  type        = bool
  default     = true
}

variable "autoscaling_min_capacity" {
  description = "Minimum task count when autoscaling is enabled."
  type        = number
  default     = 1
  validation {
    condition     = var.autoscaling_min_capacity >= 0 && floor(var.autoscaling_min_capacity) == var.autoscaling_min_capacity
    error_message = "autoscaling_min_capacity must be a non-negative integer."
  }
}

variable "autoscaling_max_capacity" {
  description = "Maximum task count when autoscaling is enabled."
  type        = number
  default     = 4
  validation {
    condition     = var.autoscaling_max_capacity >= 1 && floor(var.autoscaling_max_capacity) == var.autoscaling_max_capacity
    error_message = "autoscaling_max_capacity must be a positive integer."
  }
}

variable "autoscaling_cpu_target" {
  description = "Average CPU utilization percentage targeted by autoscaling."
  type        = number
  default     = 70
  validation {
    condition     = var.autoscaling_cpu_target >= 1 && var.autoscaling_cpu_target <= 100
    error_message = "autoscaling_cpu_target must be from 1 through 100."
  }
}

variable "ephemeral_storage_gib" {
  description = "Task ephemeral storage in GiB. Twenty uses the Fargate default."
  type        = number
  default     = 20
  validation {
    condition     = var.ephemeral_storage_gib >= 20 && var.ephemeral_storage_gib <= 200 && floor(var.ephemeral_storage_gib) == var.ephemeral_storage_gib
    error_message = "ephemeral_storage_gib must be an integer from 20 through 200."
  }
}

variable "tags" {
  description = "Additional tags to merge with standard tags."
  type        = map(string)
  default     = {}
}
