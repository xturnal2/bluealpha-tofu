locals {
  secret_name = coalesce(var.secret_name, "${var.project_name}/${var.environment}/application")

  common_tags = merge({
    Environment = var.environment
    ManagedBy   = "OpenTofu"
    Project     = var.project_name
    Template    = "aws-secrets-manager-secret"
  }, var.tags)
}

resource "aws_secretsmanager_secret" "this" {
  name                           = local.secret_name
  description                    = var.description
  kms_key_id                     = var.kms_key_id
  recovery_window_in_days        = var.recovery_window_in_days
  force_overwrite_replica_secret = var.force_overwrite_replica_secret

  dynamic "replica" {
    for_each = var.replica_regions
    content {
      region     = replica.key
      kms_key_id = replica.value.kms_key_id
    }
  }

  tags = local.common_tags
}

data "aws_iam_policy_document" "access" {
  count = length(var.allowed_reader_principal_arns) + length(var.allowed_writer_principal_arns) > 0 ? 1 : 0

  dynamic "statement" {
    for_each = length(var.allowed_reader_principal_arns) > 0 ? [1] : []
    content {
      sid       = "ExplicitReaders"
      effect    = "Allow"
      actions   = ["secretsmanager:DescribeSecret", "secretsmanager:GetSecretValue"]
      resources = [aws_secretsmanager_secret.this.arn]

      principals {
        type        = "AWS"
        identifiers = sort(tolist(var.allowed_reader_principal_arns))
      }
    }
  }

  dynamic "statement" {
    for_each = length(var.allowed_writer_principal_arns) > 0 ? [1] : []
    content {
      sid    = "ExplicitValueManagers"
      effect = "Allow"
      actions = [
        "secretsmanager:CancelRotateSecret",
        "secretsmanager:DescribeSecret",
        "secretsmanager:GetSecretValue",
        "secretsmanager:ListSecretVersionIds",
        "secretsmanager:PutSecretValue",
        "secretsmanager:RestoreSecret",
        "secretsmanager:RotateSecret",
        "secretsmanager:UpdateSecretVersionStage"
      ]
      resources = [aws_secretsmanager_secret.this.arn]

      principals {
        type        = "AWS"
        identifiers = sort(tolist(var.allowed_writer_principal_arns))
      }
    }
  }
}

resource "aws_secretsmanager_secret_policy" "access" {
  count = length(var.allowed_reader_principal_arns) + length(var.allowed_writer_principal_arns) > 0 ? 1 : 0

  secret_arn          = aws_secretsmanager_secret.this.arn
  policy              = data.aws_iam_policy_document.access[0].json
  block_public_policy = true
}
