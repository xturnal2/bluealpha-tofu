data "aws_iam_policy_document" "ecs_tasks_assume_role" {
  statement {
    actions = ["sts:AssumeRole"]
    principals {
      type        = "Service"
      identifiers = ["ecs-tasks.amazonaws.com"]
    }
  }
}

data "aws_partition" "current" {}

locals {
  name_prefix = "${var.project_name}-${var.environment}"
  valid_fargate_memory = {
    256   = [512, 1024, 2048]
    512   = [1024, 2048, 3072, 4096]
    1024  = range(2048, 8193, 1024)
    2048  = range(4096, 16385, 1024)
    4096  = range(8192, 30721, 1024)
    8192  = range(16384, 61441, 4096)
    16384 = range(32768, 122881, 8192)
  }

  common_tags = merge({
    Environment = var.environment
    ManagedBy   = "OpenTofu"
    Project     = var.project_name
    Template    = "aws-ecs-fargate-service"
  }, var.tags)
}

resource "aws_ecs_cluster" "this" {
  name = "${local.name_prefix}-cluster"

  setting {
    name  = "containerInsights"
    value = var.enable_container_insights ? "enabled" : "disabled"
  }

  tags = local.common_tags
}

resource "aws_ecs_cluster_capacity_providers" "this" {
  cluster_name = aws_ecs_cluster.this.name

  capacity_providers = ["FARGATE", "FARGATE_SPOT"]
}

resource "aws_cloudwatch_log_group" "service" {
  name              = "/ecs/${local.name_prefix}"
  retention_in_days = var.log_retention_days
  tags              = local.common_tags
}

resource "aws_iam_role" "execution" {
  name               = "${local.name_prefix}-ecs-execution"
  assume_role_policy = data.aws_iam_policy_document.ecs_tasks_assume_role.json
  tags               = local.common_tags
}

resource "aws_iam_role_policy_attachment" "execution" {
  role       = aws_iam_role.execution.name
  policy_arn = "arn:${data.aws_partition.current.partition}:iam::aws:policy/service-role/AmazonECSTaskExecutionRolePolicy"
}

data "aws_iam_policy_document" "execution_secrets" {
  count = length(var.secrets) > 0 ? 1 : 0

  statement {
    actions = [
      "secretsmanager:GetSecretValue",
      "ssm:GetParameters",
    ]
    resources = values(var.secrets)
  }
}

resource "aws_iam_role_policy" "execution_secrets" {
  count = length(var.secrets) > 0 ? 1 : 0

  name   = "read-container-secrets"
  role   = aws_iam_role.execution.id
  policy = data.aws_iam_policy_document.execution_secrets[0].json
}

resource "aws_iam_role" "task" {
  name               = "${local.name_prefix}-ecs-task"
  assume_role_policy = data.aws_iam_policy_document.ecs_tasks_assume_role.json
  tags               = local.common_tags
}

data "aws_iam_policy_document" "ecs_exec" {
  count = var.enable_execute_command ? 1 : 0

  statement {
    actions = [
      "ssmmessages:CreateControlChannel",
      "ssmmessages:CreateDataChannel",
      "ssmmessages:OpenControlChannel",
      "ssmmessages:OpenDataChannel",
    ]
    resources = ["*"]
  }
}

resource "aws_iam_role_policy" "ecs_exec" {
  count = var.enable_execute_command ? 1 : 0

  name   = "ecs-exec"
  role   = aws_iam_role.task.id
  policy = data.aws_iam_policy_document.ecs_exec[0].json
}

resource "aws_security_group" "load_balancer" {
  name_prefix = "${local.name_prefix}-alb-"
  description = "Ingress to ${local.name_prefix} load balancer"
  vpc_id      = var.vpc_id

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = merge(local.common_tags, { Name = "${local.name_prefix}-alb" })
}

resource "aws_vpc_security_group_ingress_rule" "load_balancer_cidr" {
  for_each = var.allowed_ingress_cidrs

  security_group_id = aws_security_group.load_balancer.id
  cidr_ipv4         = each.value
  from_port         = var.certificate_arn != null ? 443 : 80
  to_port           = var.certificate_arn != null ? 443 : 80
  ip_protocol       = "tcp"
  description       = "Allowed client CIDR"
}

resource "aws_vpc_security_group_ingress_rule" "load_balancer_security_group" {
  for_each = var.allowed_ingress_security_group_ids

  security_group_id            = aws_security_group.load_balancer.id
  referenced_security_group_id = each.value
  from_port                    = var.certificate_arn != null ? 443 : 80
  to_port                      = var.certificate_arn != null ? 443 : 80
  ip_protocol                  = "tcp"
  description                  = "Allowed client security group"
}

resource "aws_vpc_security_group_ingress_rule" "load_balancer_http_redirect" {
  for_each = var.certificate_arn != null && var.redirect_http_to_https ? var.allowed_ingress_cidrs : toset([])

  security_group_id = aws_security_group.load_balancer.id
  cidr_ipv4         = each.value
  from_port         = 80
  to_port           = 80
  ip_protocol       = "tcp"
  description       = "HTTP redirect client CIDR"
}

resource "aws_vpc_security_group_ingress_rule" "load_balancer_http_redirect_security_group" {
  for_each = var.certificate_arn != null && var.redirect_http_to_https ? var.allowed_ingress_security_group_ids : toset([])

  security_group_id            = aws_security_group.load_balancer.id
  referenced_security_group_id = each.value
  from_port                    = 80
  to_port                      = 80
  ip_protocol                  = "tcp"
  description                  = "HTTP redirect client security group"
}

resource "aws_security_group" "tasks" {
  name_prefix = "${local.name_prefix}-tasks-"
  description = "Traffic to ${local.name_prefix} Fargate tasks"
  vpc_id      = var.vpc_id

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = merge(local.common_tags, { Name = "${local.name_prefix}-tasks" })
}

resource "aws_vpc_security_group_ingress_rule" "tasks_from_load_balancer" {
  security_group_id            = aws_security_group.tasks.id
  referenced_security_group_id = aws_security_group.load_balancer.id
  from_port                    = var.container_port
  to_port                      = var.container_port
  ip_protocol                  = "tcp"
  description                  = "Application traffic from the load balancer"
}

resource "aws_lb" "this" {
  name               = substr("${local.name_prefix}-alb", 0, 32)
  internal           = var.internal_load_balancer
  load_balancer_type = "application"
  security_groups    = [aws_security_group.load_balancer.id]
  subnets            = var.load_balancer_subnet_ids

  enable_deletion_protection = false
  drop_invalid_header_fields = true
  tags                       = local.common_tags
}

resource "aws_lb_target_group" "service" {
  name                 = substr("${local.name_prefix}-tg", 0, 32)
  port                 = var.container_port
  protocol             = "HTTP"
  target_type          = "ip"
  vpc_id               = var.vpc_id
  deregistration_delay = 30

  health_check {
    enabled             = true
    path                = var.health_check_path
    protocol            = "HTTP"
    matcher             = "200-399"
    interval            = 30
    timeout             = 5
    healthy_threshold   = 2
    unhealthy_threshold = 3
  }

  tags = local.common_tags
}

resource "aws_lb_listener" "http" {
  count = var.certificate_arn == null || var.redirect_http_to_https ? 1 : 0

  load_balancer_arn = aws_lb.this.arn
  port              = 80
  protocol          = "HTTP"

  default_action {
    type = var.certificate_arn != null && var.redirect_http_to_https ? "redirect" : "forward"

    target_group_arn = var.certificate_arn != null && var.redirect_http_to_https ? null : aws_lb_target_group.service.arn

    dynamic "redirect" {
      for_each = var.certificate_arn != null && var.redirect_http_to_https ? [1] : []
      content {
        port        = "443"
        protocol    = "HTTPS"
        status_code = "HTTP_301"
      }
    }
  }
}

resource "aws_lb_listener" "https" {
  count = var.certificate_arn != null ? 1 : 0

  load_balancer_arn = aws_lb.this.arn
  port              = 443
  protocol          = "HTTPS"
  ssl_policy        = "ELBSecurityPolicy-TLS13-1-2-2021-06"
  certificate_arn   = var.certificate_arn

  default_action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.service.arn
  }
}

resource "aws_ecs_task_definition" "service" {
  family                   = local.name_prefix
  requires_compatibilities = ["FARGATE"]
  network_mode             = "awsvpc"
  cpu                      = tostring(var.cpu)
  memory                   = tostring(var.memory)
  execution_role_arn       = aws_iam_role.execution.arn
  task_role_arn            = aws_iam_role.task.arn

  runtime_platform {
    operating_system_family = "LINUX"
    cpu_architecture        = var.cpu_architecture
  }

  dynamic "ephemeral_storage" {
    for_each = var.ephemeral_storage_gib > 20 ? [1] : []
    content {
      size_in_gib = var.ephemeral_storage_gib
    }
  }

  container_definitions = jsonencode([{
    name      = "app"
    image     = var.container_image
    essential = true
    portMappings = [{
      name          = "http"
      containerPort = var.container_port
      hostPort      = var.container_port
      protocol      = "tcp"
      appProtocol   = "http"
    }]
    environment = [for name, value in var.environment_variables : {
      name  = name
      value = value
    }]
    secrets = [for name, value_from in var.secrets : {
      name      = name
      valueFrom = value_from
    }]
    logConfiguration = {
      logDriver = "awslogs"
      options = {
        awslogs-group         = aws_cloudwatch_log_group.service.name
        awslogs-region        = var.aws_region
        awslogs-stream-prefix = "app"
      }
    }
  }])

  tags = local.common_tags

  lifecycle {
    precondition {
      condition     = contains(local.valid_fargate_memory[var.cpu], var.memory)
      error_message = "memory is not compatible with the selected Fargate cpu value."
    }
  }
}

resource "aws_ecs_service" "this" {
  name                   = "${local.name_prefix}-service"
  cluster                = aws_ecs_cluster.this.id
  task_definition        = aws_ecs_task_definition.service.arn
  desired_count          = var.desired_count
  enable_execute_command = var.enable_execute_command
  platform_version       = "LATEST"

  deployment_minimum_healthy_percent = 50
  deployment_maximum_percent         = 200
  health_check_grace_period_seconds  = 60

  capacity_provider_strategy {
    capacity_provider = var.use_fargate_spot ? "FARGATE_SPOT" : "FARGATE"
    weight            = 1
  }

  deployment_circuit_breaker {
    enable   = true
    rollback = true
  }

  network_configuration {
    subnets          = var.task_subnet_ids
    security_groups  = [aws_security_group.tasks.id]
    assign_public_ip = var.assign_public_ip
  }

  load_balancer {
    target_group_arn = aws_lb_target_group.service.arn
    container_name   = "app"
    container_port   = var.container_port
  }

  lifecycle {
    ignore_changes = [desired_count]

    precondition {
      condition     = !var.enable_autoscaling || (var.autoscaling_min_capacity <= var.desired_count && var.desired_count <= var.autoscaling_max_capacity)
      error_message = "desired_count must be between autoscaling_min_capacity and autoscaling_max_capacity."
    }
  }

  depends_on = [
    aws_ecs_cluster_capacity_providers.this,
    aws_lb_listener.http,
    aws_lb_listener.https,
  ]
  tags = local.common_tags
}

resource "aws_appautoscaling_target" "service" {
  count = var.enable_autoscaling ? 1 : 0

  max_capacity       = var.autoscaling_max_capacity
  min_capacity       = var.autoscaling_min_capacity
  resource_id        = "service/${aws_ecs_cluster.this.name}/${aws_ecs_service.this.name}"
  scalable_dimension = "ecs:service:DesiredCount"
  service_namespace  = "ecs"
}

resource "aws_appautoscaling_policy" "cpu" {
  count = var.enable_autoscaling ? 1 : 0

  name               = "${local.name_prefix}-cpu"
  policy_type        = "TargetTrackingScaling"
  resource_id        = aws_appautoscaling_target.service[0].resource_id
  scalable_dimension = aws_appautoscaling_target.service[0].scalable_dimension
  service_namespace  = aws_appautoscaling_target.service[0].service_namespace

  target_tracking_scaling_policy_configuration {
    target_value       = var.autoscaling_cpu_target
    scale_in_cooldown  = 300
    scale_out_cooldown = 60

    predefined_metric_specification {
      predefined_metric_type = "ECSServiceAverageCPUUtilization"
    }
  }
}
