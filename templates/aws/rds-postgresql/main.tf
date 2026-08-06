data "aws_partition" "current" {}

locals {
  name_prefix = "${var.project_name}-${var.environment}"
  common_tags = merge({
    Environment = var.environment
    ManagedBy   = "OpenTofu"
    Project     = var.project_name
    Template    = "aws-rds-postgresql"
  }, var.tags)
}

resource "aws_db_subnet_group" "this" {
  name       = "${local.name_prefix}-postgresql"
  subnet_ids = var.subnet_ids
  tags       = merge(local.common_tags, { Name = "${local.name_prefix}-postgresql" })
}

resource "aws_security_group" "database" {
  name_prefix = "${local.name_prefix}-postgresql-"
  description = "Client access to ${local.name_prefix} PostgreSQL"
  vpc_id      = var.vpc_id
  tags        = merge(local.common_tags, { Name = "${local.name_prefix}-postgresql" })
}

resource "aws_vpc_security_group_ingress_rule" "security_group" {
  for_each = var.allowed_security_group_ids

  security_group_id            = aws_security_group.database.id
  referenced_security_group_id = each.value
  from_port                    = 5432
  to_port                      = 5432
  ip_protocol                  = "tcp"
  description                  = "PostgreSQL client security group"
}

resource "aws_vpc_security_group_ingress_rule" "cidr" {
  for_each = var.allowed_cidrs

  security_group_id = aws_security_group.database.id
  cidr_ipv4         = each.value
  from_port         = 5432
  to_port           = 5432
  ip_protocol       = "tcp"
  description       = "PostgreSQL client CIDR"
}

data "aws_iam_policy_document" "monitoring_assume_role" {
  count = var.monitoring_interval_seconds > 0 ? 1 : 0

  statement {
    actions = ["sts:AssumeRole"]
    principals {
      type        = "Service"
      identifiers = ["monitoring.rds.amazonaws.com"]
    }
  }
}

resource "aws_iam_role" "monitoring" {
  count = var.monitoring_interval_seconds > 0 ? 1 : 0

  name               = "${local.name_prefix}-rds-monitoring"
  assume_role_policy = data.aws_iam_policy_document.monitoring_assume_role[0].json
  tags               = local.common_tags
}

resource "aws_iam_role_policy_attachment" "monitoring" {
  count = var.monitoring_interval_seconds > 0 ? 1 : 0

  role       = aws_iam_role.monitoring[0].name
  policy_arn = "arn:${data.aws_partition.current.partition}:iam::aws:policy/service-role/AmazonRDSEnhancedMonitoringRole"
}

resource "aws_db_instance" "this" {
  identifier = "${local.name_prefix}-postgresql"

  engine         = "postgres"
  engine_version = var.engine_version
  instance_class = var.instance_class
  db_name        = var.database_name
  username       = var.master_username
  port           = 5432

  manage_master_user_password   = var.manage_master_user_password
  password                      = var.manage_master_user_password ? null : var.master_password
  master_user_secret_kms_key_id = var.manage_master_user_password ? var.master_user_secret_kms_key_id : null

  allocated_storage     = var.allocated_storage_gib
  max_allocated_storage = var.max_allocated_storage_gib
  storage_type          = "gp3"
  storage_encrypted     = true
  kms_key_id            = var.storage_kms_key_id

  db_subnet_group_name   = aws_db_subnet_group.this.name
  vpc_security_group_ids = [aws_security_group.database.id]
  publicly_accessible    = var.publicly_accessible
  multi_az               = var.multi_az
  network_type           = "IPV4"

  backup_retention_period  = var.backup_retention_days
  backup_window            = var.backup_window
  maintenance_window       = var.maintenance_window
  copy_tags_to_snapshot    = true
  delete_automated_backups = false

  deletion_protection        = var.deletion_protection
  skip_final_snapshot        = var.skip_final_snapshot
  final_snapshot_identifier  = var.skip_final_snapshot ? null : coalesce(var.final_snapshot_identifier, "${local.name_prefix}-final")
  apply_immediately          = var.apply_immediately
  auto_minor_version_upgrade = var.auto_minor_version_upgrade

  iam_database_authentication_enabled = var.enable_iam_database_authentication
  enabled_cloudwatch_logs_exports     = var.cloudwatch_log_exports

  performance_insights_enabled          = var.enable_performance_insights
  performance_insights_retention_period = var.enable_performance_insights ? var.performance_insights_retention_days : null

  monitoring_interval = var.monitoring_interval_seconds
  monitoring_role_arn = var.monitoring_interval_seconds > 0 ? aws_iam_role.monitoring[0].arn : null

  tags = local.common_tags

  lifecycle {
    precondition {
      condition     = var.manage_master_user_password || var.master_password != null
      error_message = "master_password is required when manage_master_user_password is false."
    }
    precondition {
      condition     = var.max_allocated_storage_gib == 0 || var.max_allocated_storage_gib >= ceil(var.allocated_storage_gib * 1.1)
      error_message = "max_allocated_storage_gib must be zero or at least 10 percent greater than allocated_storage_gib."
    }
    precondition {
      condition     = !var.publicly_accessible || length(var.allowed_cidrs) > 0 || length(var.allowed_security_group_ids) > 0
      error_message = "A publicly accessible database requires at least one explicit allowed source."
    }
  }

  depends_on = [aws_iam_role_policy_attachment.monitoring]
}
