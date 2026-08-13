data "aws_caller_identity" "current" {}
data "aws_partition" "current" {}

locals {
  alias_name = coalesce(var.alias_name, "${var.project_name}-${var.environment}")
  root_arn   = "arn:${data.aws_partition.current.partition}:iam::${data.aws_caller_identity.current.account_id}:root"

  common_tags = merge({
    Environment = var.environment
    ManagedBy   = "OpenTofu"
    Project     = var.project_name
    Template    = "aws-kms-key"
  }, var.tags)
}

data "aws_iam_policy_document" "key" {
  statement {
    sid       = "EnableAccountIAMPermissions"
    effect    = "Allow"
    actions   = ["kms:*"]
    resources = ["*"]

    principals {
      type        = "AWS"
      identifiers = [local.root_arn]
    }
  }

  dynamic "statement" {
    for_each = length(var.allowed_key_administrator_arns) > 0 ? [1] : []
    content {
      sid    = "ExplicitKeyAdministrators"
      effect = "Allow"
      actions = [
        "kms:CancelKeyDeletion",
        "kms:CreateAlias",
        "kms:CreateGrant",
        "kms:DescribeKey",
        "kms:DisableKey",
        "kms:EnableKey",
        "kms:EnableKeyRotation",
        "kms:GetKeyPolicy",
        "kms:GetKeyRotationStatus",
        "kms:ListGrants",
        "kms:ListKeyPolicies",
        "kms:ListResourceTags",
        "kms:PutKeyPolicy",
        "kms:RevokeGrant",
        "kms:TagResource",
        "kms:UntagResource",
        "kms:UpdateAlias",
        "kms:UpdateKeyDescription"
      ]
      resources = ["*"]

      principals {
        type        = "AWS"
        identifiers = sort(tolist(var.allowed_key_administrator_arns))
      }
    }
  }

  dynamic "statement" {
    for_each = length(var.allowed_cryptographic_user_arns) > 0 ? [1] : []
    content {
      sid    = "ExplicitCryptographicUsers"
      effect = "Allow"
      actions = [
        "kms:Decrypt",
        "kms:DescribeKey",
        "kms:Encrypt",
        "kms:GenerateDataKey",
        "kms:GenerateDataKeyWithoutPlaintext",
        "kms:ReEncryptFrom",
        "kms:ReEncryptTo"
      ]
      resources = ["*"]

      principals {
        type        = "AWS"
        identifiers = sort(tolist(var.allowed_cryptographic_user_arns))
      }
    }
  }
}

resource "aws_kms_key" "this" {
  description              = var.description
  key_usage                = "ENCRYPT_DECRYPT"
  customer_master_key_spec = "SYMMETRIC_DEFAULT"
  enable_key_rotation      = var.enable_key_rotation
  rotation_period_in_days  = var.enable_key_rotation ? var.rotation_period_in_days : null
  deletion_window_in_days  = var.deletion_window_in_days
  multi_region             = var.multi_region
  policy                   = data.aws_iam_policy_document.key.json
  tags                     = local.common_tags
}

resource "aws_kms_alias" "this" {
  name          = "alias/${local.alias_name}"
  target_key_id = aws_kms_key.this.key_id
}
