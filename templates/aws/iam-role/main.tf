locals {
  role_name = coalesce(var.role_name, "${var.project_name}-${var.environment}-workload")

  trust_statements = concat(
    length(var.trusted_service_principals) > 0 ? [{
      Effect = "Allow"
      Principal = {
        Service = sort(tolist(var.trusted_service_principals))
      }
      Action = "sts:AssumeRole"
    }] : [],
    length(var.trusted_aws_principal_arns) > 0 ? [{
      Effect = "Allow"
      Principal = {
        AWS = sort(tolist(var.trusted_aws_principal_arns))
      }
      Action = "sts:AssumeRole"
      Condition = merge(
        var.external_id == null ? {} : {
          StringEquals = { "sts:ExternalId" = var.external_id }
        },
        var.require_mfa ? {
          Bool = { "aws:MultiFactorAuthPresent" = "true" }
        } : {}
      )
    }] : []
  )

  common_tags = merge(var.tags, {
    Environment = var.environment
    ManagedBy   = "OpenTofu"
    Project     = var.project_name
    Template    = "aws/iam-role"
  })
}

resource "aws_iam_role" "this" {
  name                  = local.role_name
  description           = var.description
  path                  = var.path
  max_session_duration  = var.max_session_duration_seconds
  permissions_boundary  = var.permissions_boundary_arn
  force_detach_policies = var.force_detach_policies
  assume_role_policy = jsonencode({
    Version   = "2012-10-17"
    Statement = local.trust_statements
  })
  tags = local.common_tags

  lifecycle {
    precondition {
      condition     = length(local.trust_statements) > 0
      error_message = "At least one trusted service principal or AWS principal ARN is required."
    }
    precondition {
      condition     = var.external_id == null || length(var.trusted_aws_principal_arns) > 0
      error_message = "external_id requires at least one trusted AWS principal ARN."
    }
    precondition {
      condition     = !var.require_mfa || length(var.trusted_aws_principal_arns) > 0
      error_message = "require_mfa requires at least one trusted AWS principal ARN."
    }
  }
}

resource "aws_iam_role_policy_attachment" "this" {
  for_each = var.managed_policy_arns

  role       = aws_iam_role.this.name
  policy_arn = each.value
}

resource "aws_iam_role_policy" "this" {
  for_each = var.inline_policies

  name   = each.key
  role   = aws_iam_role.this.id
  policy = each.value
}
