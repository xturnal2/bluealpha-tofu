locals {
  name_prefix = "${var.project_name}-${var.environment}"
  common_tags = merge({
    Architecture = "aws-connected-app-platform"
  }, var.tags)
}

resource "terraform_data" "guardrails" {
  lifecycle {
    precondition {
      condition     = var.internal_load_balancer || var.certificate_arn != null
      error_message = "Internet-facing deployments require certificate_arn for HTTPS."
    }
    precondition {
      condition     = var.desired_count <= var.autoscaling_max_capacity
      error_message = "desired_count must not exceed autoscaling_max_capacity."
    }
  }
}

module "network" {
  source = "../../../templates/aws/vpc"

  aws_region              = var.aws_region
  project_name            = var.project_name
  environment             = var.environment
  vpc_cidr                = var.vpc_cidr
  availability_zone_count = var.availability_zone_count
  enable_nat_gateway      = var.enable_nat_gateway
  single_nat_gateway      = var.single_nat_gateway
  enable_flow_logs        = var.enable_flow_logs
  flow_log_retention_days = var.log_retention_days
  tags                    = local.common_tags
}

resource "aws_security_group" "application_data_client" {
  name_prefix = "${local.name_prefix}-data-client-"
  description = "Shared identity for application access to private data services"
  vpc_id      = module.network.vpc_id

  tags = merge(local.common_tags, {
    Name      = "${local.name_prefix}-data-client"
    ManagedBy = "OpenTofu"
  })
}

module "queue" {
  source = "../../../templates/aws/sqs-queue"

  aws_region                    = var.aws_region
  project_name                  = var.project_name
  environment                   = var.environment
  fifo_queue                    = var.queue_fifo
  content_based_deduplication   = var.queue_fifo
  create_dead_letter_queue      = true
  max_receive_count             = 5
  visibility_timeout_seconds    = 60
  receive_wait_time_seconds     = 20
  dead_letter_retention_seconds = 1209600
  tags                          = local.common_tags
}

module "table" {
  source = "../../../templates/aws/dynamodb-table"

  aws_region                     = var.aws_region
  project_name                   = var.project_name
  environment                    = var.environment
  hash_key                       = "id"
  hash_key_type                  = "S"
  billing_mode                   = "PAY_PER_REQUEST"
  deletion_protection_enabled    = var.dynamodb_deletion_protection
  point_in_time_recovery_enabled = var.dynamodb_point_in_time_recovery
  ttl_enabled                    = true
  ttl_attribute_name             = "expires_at"
  tags                           = local.common_tags
}

module "database" {
  source = "../../../templates/aws/rds-postgresql"

  aws_region                  = var.aws_region
  project_name                = var.project_name
  environment                 = var.environment
  vpc_id                      = module.network.vpc_id
  subnet_ids                  = module.network.private_subnet_ids
  allowed_security_group_ids  = [aws_security_group.application_data_client.id]
  database_name               = var.database_name
  instance_class              = var.database_instance_class
  multi_az                    = var.database_multi_az
  publicly_accessible         = false
  backup_retention_days       = var.database_backup_retention_days
  deletion_protection         = var.database_deletion_protection
  skip_final_snapshot         = var.database_skip_final_snapshot
  manage_master_user_password = true
  enable_performance_insights = false
  monitoring_interval_seconds = 0
  tags                        = local.common_tags
}

module "service" {
  source = "../../../templates/aws/ecs-fargate-service"

  aws_region                         = var.aws_region
  project_name                       = var.project_name
  environment                        = var.environment
  vpc_id                             = module.network.vpc_id
  load_balancer_subnet_ids           = var.internal_load_balancer ? module.network.private_subnet_ids : module.network.public_subnet_ids
  task_subnet_ids                    = module.network.private_subnet_ids
  additional_task_security_group_ids = [aws_security_group.application_data_client.id]
  container_image                    = var.container_image
  container_port                     = var.container_port
  health_check_path                  = var.health_check_path
  desired_count                      = var.desired_count
  internal_load_balancer             = var.internal_load_balancer
  allowed_ingress_cidrs              = var.allowed_ingress_cidrs
  certificate_arn                    = var.certificate_arn
  assign_public_ip                   = false
  enable_autoscaling                 = true
  autoscaling_min_capacity           = var.desired_count
  autoscaling_max_capacity           = var.autoscaling_max_capacity
  log_retention_days                 = var.log_retention_days

  environment_variables = {
    AWS_REGION          = var.aws_region
    DATABASE_HOST       = module.database.address
    DATABASE_NAME       = module.database.database_name
    DATABASE_PORT       = tostring(module.database.port)
    DYNAMODB_TABLE_NAME = module.table.table_name
    SQS_QUEUE_URL       = module.queue.queue_url
  }

  secrets = {
    DATABASE_CREDENTIALS = module.database.master_user_secret_arn
  }

  task_role_policy_statements = [
    {
      sid = "QueueAccess"
      actions = [
        "sqs:ChangeMessageVisibility",
        "sqs:DeleteMessage",
        "sqs:GetQueueAttributes",
        "sqs:ReceiveMessage",
        "sqs:SendMessage",
      ]
      resources = [module.queue.queue_arn]
    },
    {
      sid = "TableAccess"
      actions = [
        "dynamodb:BatchGetItem",
        "dynamodb:BatchWriteItem",
        "dynamodb:DeleteItem",
        "dynamodb:DescribeTable",
        "dynamodb:GetItem",
        "dynamodb:PutItem",
        "dynamodb:Query",
        "dynamodb:UpdateItem",
      ]
      resources = [
        module.table.table_arn,
        "${module.table.table_arn}/index/*",
      ]
    },
  ]

  tags = local.common_tags
}
