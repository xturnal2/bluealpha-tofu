variable "project_name" {
  description = "Short project identifier used in names and tags."
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
  description = "AWS region for the database."
  type        = string
  default     = "us-east-1"
}

variable "vpc_id" {
  description = "VPC ID for the database security group."
  type        = string
}

variable "subnet_ids" {
  description = "Private subnet IDs spanning at least two availability zones."
  type        = list(string)
  validation {
    condition     = length(distinct(var.subnet_ids)) >= 2
    error_message = "subnet_ids must contain at least two unique private subnet IDs."
  }
}

variable "allowed_security_group_ids" {
  description = "Security group IDs permitted to connect to PostgreSQL."
  type        = set(string)
  default     = []
}

variable "allowed_cidrs" {
  description = "IPv4 CIDRs permitted to connect to PostgreSQL. Security-group references are preferred."
  type        = set(string)
  default     = []
  validation {
    condition     = alltrue([for cidr in var.allowed_cidrs : can(cidrnetmask(cidr))])
    error_message = "Every allowed_cidrs value must be a valid IPv4 CIDR."
  }
}

variable "database_name" {
  description = "Initial PostgreSQL database name."
  type        = string
  default     = "app"
  validation {
    condition     = can(regex("^[A-Za-z][A-Za-z0-9_]{0,62}$", var.database_name))
    error_message = "database_name must start with a letter and contain at most 63 letters, numbers, or underscores."
  }
}

variable "master_username" {
  description = "Master database username."
  type        = string
  default     = "dbadmin"
  validation {
    condition     = can(regex("^[A-Za-z][A-Za-z0-9_]{0,62}$", var.master_username)) && !contains(["admin", "postgres", "rdsadmin", "root"], lower(var.master_username))
    error_message = "master_username must be a valid non-reserved PostgreSQL identifier."
  }
}

variable "manage_master_user_password" {
  description = "Let RDS generate and rotate the master password in AWS Secrets Manager."
  type        = bool
  default     = true
}

variable "master_password" {
  description = "Master password when RDS-managed credentials are disabled. Avoid tfvars because this value is stored in state."
  type        = string
  default     = null
  sensitive   = true
}

variable "master_user_secret_kms_key_id" {
  description = "Optional KMS key ARN or ID for the RDS-managed master secret."
  type        = string
  default     = null
}

variable "engine_version" {
  description = "PostgreSQL engine version. Null lets AWS select its current default. Pin for controlled production upgrades."
  type        = string
  default     = null
}

variable "instance_class" {
  description = "RDS instance class."
  type        = string
  default     = "db.t4g.micro"
}

variable "allocated_storage_gib" {
  description = "Initial gp3 storage allocation in GiB."
  type        = number
  default     = 20
  validation {
    condition     = var.allocated_storage_gib >= 20 && floor(var.allocated_storage_gib) == var.allocated_storage_gib
    error_message = "allocated_storage_gib must be an integer of at least 20."
  }
}

variable "max_allocated_storage_gib" {
  description = "Storage autoscaling ceiling in GiB. Zero disables autoscaling."
  type        = number
  default     = 100
  validation {
    condition     = var.max_allocated_storage_gib == 0 || (var.max_allocated_storage_gib >= 21 && floor(var.max_allocated_storage_gib) == var.max_allocated_storage_gib)
    error_message = "max_allocated_storage_gib must be zero or an integer of at least 21."
  }
}

variable "storage_kms_key_id" {
  description = "Optional customer-managed KMS key ARN for database storage. Null uses the AWS-managed RDS key."
  type        = string
  default     = null
}

variable "multi_az" {
  description = "Maintain a synchronous standby in another availability zone."
  type        = bool
  default     = false
}

variable "publicly_accessible" {
  description = "Assign a publicly resolvable endpoint. Private access is strongly recommended."
  type        = bool
  default     = false
}

variable "backup_retention_days" {
  description = "Automated backup retention. Zero disables automated backups."
  type        = number
  default     = 7
  validation {
    condition     = var.backup_retention_days >= 0 && var.backup_retention_days <= 35 && floor(var.backup_retention_days) == var.backup_retention_days
    error_message = "backup_retention_days must be an integer from 0 through 35."
  }
}

variable "backup_window" {
  description = "Optional daily UTC backup window, for example 03:00-04:00."
  type        = string
  default     = null
}

variable "maintenance_window" {
  description = "Optional weekly UTC maintenance window, for example Sun:05:00-Sun:06:00."
  type        = string
  default     = null
}

variable "deletion_protection" {
  description = "Prevent database deletion until explicitly disabled."
  type        = bool
  default     = true
}

variable "skip_final_snapshot" {
  description = "Skip the final snapshot during destroy. Enabling can cause unrecoverable data loss."
  type        = bool
  default     = false
}

variable "final_snapshot_identifier" {
  description = "Final snapshot name when skip_final_snapshot is false. Null uses <project>-<environment>-final."
  type        = string
  default     = null
}

variable "apply_immediately" {
  description = "Apply eligible database modifications immediately instead of during maintenance."
  type        = bool
  default     = false
}

variable "auto_minor_version_upgrade" {
  description = "Allow automatic minor engine upgrades during maintenance windows."
  type        = bool
  default     = true
}

variable "enable_iam_database_authentication" {
  description = "Enable IAM database authentication in addition to password authentication."
  type        = bool
  default     = false
}

variable "enable_performance_insights" {
  description = "Enable RDS Performance Insights."
  type        = bool
  default     = false
}

variable "performance_insights_retention_days" {
  description = "Performance Insights retention period."
  type        = number
  default     = 7
  validation {
    condition = (
      var.performance_insights_retention_days == 7 ||
      var.performance_insights_retention_days == 731 ||
      (var.performance_insights_retention_days >= 31 && var.performance_insights_retention_days <= 713 && var.performance_insights_retention_days % 31 == 0)
    )
    error_message = "Use 7, 731, or a multiple of 31 from 31 through 713 days."
  }
}

variable "monitoring_interval_seconds" {
  description = "Enhanced Monitoring interval. Zero disables enhanced monitoring."
  type        = number
  default     = 0
  validation {
    condition     = contains([0, 1, 5, 10, 15, 30, 60], var.monitoring_interval_seconds)
    error_message = "monitoring_interval_seconds must be 0, 1, 5, 10, 15, 30, or 60."
  }
}

variable "cloudwatch_log_exports" {
  description = "PostgreSQL logs exported to CloudWatch Logs."
  type        = set(string)
  default     = ["postgresql", "upgrade"]
  validation {
    condition     = alltrue([for log_type in var.cloudwatch_log_exports : contains(["postgresql", "upgrade"], log_type)])
    error_message = "cloudwatch_log_exports supports postgresql and upgrade."
  }
}

variable "tags" {
  description = "Additional tags to merge with standard tags."
  type        = map(string)
  default     = {}
}
