locals {
  name_prefix   = "${var.project_name}-${var.environment}"
  function_name = "${local.name_prefix}-api"

  common_tags = merge({
    Environment = var.environment
    ManagedBy   = "OpenTofu"
    Project     = var.project_name
    Template    = "aws-lambda-api"
  }, var.tags)
}

data "archive_file" "function" {
  type        = "zip"
  source_file = "${path.module}/${var.source_file}"
  output_path = "${path.module}/lambda.zip"
}

data "aws_iam_policy_document" "assume_role" {
  statement {
    effect  = "Allow"
    actions = ["sts:AssumeRole"]

    principals {
      type        = "Service"
      identifiers = ["lambda.amazonaws.com"]
    }
  }
}

resource "aws_iam_role" "function" {
  name               = "${local.function_name}-role"
  assume_role_policy = data.aws_iam_policy_document.assume_role.json
  tags               = local.common_tags
}

resource "aws_iam_role_policy_attachment" "basic_execution" {
  role       = aws_iam_role.function.name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AWSLambdaBasicExecutionRole"
}

resource "aws_iam_role_policy_attachment" "vpc_access" {
  count = length(var.vpc_subnet_ids) > 0 ? 1 : 0

  role       = aws_iam_role.function.name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AWSLambdaVPCAccessExecutionRole"
}

resource "aws_iam_role_policy_attachment" "xray" {
  count = var.tracing_mode == "Active" ? 1 : 0

  role       = aws_iam_role.function.name
  policy_arn = "arn:aws:iam::aws:policy/AWSXRayDaemonWriteAccess"
}

resource "aws_cloudwatch_log_group" "function" {
  name              = "/aws/lambda/${local.function_name}"
  retention_in_days = var.log_retention_days
  tags              = local.common_tags
}

resource "aws_lambda_function" "this" {
  function_name                  = local.function_name
  description                    = var.function_description
  role                           = aws_iam_role.function.arn
  filename                       = data.archive_file.function.output_path
  source_code_hash               = data.archive_file.function.output_base64sha256
  handler                        = var.handler
  runtime                        = var.runtime
  architectures                  = [var.architecture]
  memory_size                    = var.memory_size
  timeout                        = var.timeout_seconds
  reserved_concurrent_executions = var.reserved_concurrent_executions
  tags                           = local.common_tags

  ephemeral_storage {
    size = var.ephemeral_storage_mb
  }

  environment {
    variables = var.environment_variables
  }

  logging_config {
    log_format = "JSON"
  }

  tracing_config {
    mode = var.tracing_mode
  }

  dynamic "vpc_config" {
    for_each = length(var.vpc_subnet_ids) > 0 ? [1] : []
    content {
      subnet_ids         = var.vpc_subnet_ids
      security_group_ids = var.vpc_security_group_ids
    }
  }

  depends_on = [
    aws_cloudwatch_log_group.function,
    aws_iam_role_policy_attachment.basic_execution,
    aws_iam_role_policy_attachment.vpc_access,
    aws_iam_role_policy_attachment.xray,
  ]

  lifecycle {
    precondition {
      condition     = (length(var.vpc_subnet_ids) == 0) == (length(var.vpc_security_group_ids) == 0)
      error_message = "vpc_subnet_ids and vpc_security_group_ids must both be empty or both be populated."
    }
  }
}

resource "aws_cloudwatch_log_group" "api" {
  name              = "/aws/apigateway/${local.function_name}"
  retention_in_days = var.log_retention_days
  tags              = local.common_tags
}

resource "aws_apigatewayv2_api" "this" {
  name          = local.function_name
  protocol_type = "HTTP"
  description   = "HTTP API for ${aws_lambda_function.this.function_name}"
  tags          = local.common_tags

  dynamic "cors_configuration" {
    for_each = length(var.cors_allowed_origins) > 0 ? [1] : []
    content {
      allow_credentials = var.cors_allow_credentials
      allow_headers     = var.cors_allowed_headers
      allow_methods     = var.cors_allowed_methods
      allow_origins     = var.cors_allowed_origins
      max_age           = var.cors_max_age_seconds
    }
  }

  lifecycle {
    precondition {
      condition     = !var.cors_allow_credentials || !contains(var.cors_allowed_origins, "*")
      error_message = "CORS credentials cannot be enabled when allowed origins contains *."
    }
  }
}

resource "aws_apigatewayv2_integration" "function" {
  api_id                 = aws_apigatewayv2_api.this.id
  integration_type       = "AWS_PROXY"
  integration_uri        = aws_lambda_function.this.invoke_arn
  integration_method     = "POST"
  payload_format_version = "2.0"
  timeout_milliseconds   = 30000
}

resource "aws_apigatewayv2_route" "default" {
  api_id             = aws_apigatewayv2_api.this.id
  route_key          = "$default"
  authorization_type = "NONE"
  target             = "integrations/${aws_apigatewayv2_integration.function.id}"
}

resource "aws_apigatewayv2_stage" "default" {
  api_id      = aws_apigatewayv2_api.this.id
  name        = "$default"
  auto_deploy = true
  tags        = local.common_tags

  access_log_settings {
    destination_arn = aws_cloudwatch_log_group.api.arn
    format = jsonencode({
      http_method       = "$context.httpMethod"
      integration_error = "$context.integrationErrorMessage"
      ip                = "$context.identity.sourceIp"
      latency           = "$context.responseLatency"
      protocol          = "$context.protocol"
      request_id        = "$context.requestId"
      route_key         = "$context.routeKey"
      status            = "$context.status"
    })
  }

  default_route_settings {
    detailed_metrics_enabled = true
    throttling_burst_limit   = var.throttle_burst_limit
    throttling_rate_limit    = var.throttle_rate_limit
  }
}

resource "aws_lambda_permission" "api" {
  statement_id  = "AllowHttpApiInvocation"
  action        = "lambda:InvokeFunction"
  function_name = aws_lambda_function.this.function_name
  principal     = "apigateway.amazonaws.com"
  source_arn    = "${aws_apigatewayv2_api.this.execution_arn}/*/*"
}
