locals {
  bucket_name = coalesce(var.bucket_name, "${var.project_name}-${var.environment}-${random_string.suffix.result}")

  common_tags = merge({
    Environment = var.environment
    ManagedBy   = "OpenTofu"
    Project     = var.project_name
    Template    = "aws-s3-bucket"
  }, var.tags)
}

resource "random_string" "suffix" {
  length  = 8
  special = false
  upper   = false
}

resource "aws_s3_bucket" "this" {
  bucket        = local.bucket_name
  force_destroy = var.force_destroy
  tags          = local.common_tags
}

resource "aws_s3_bucket_ownership_controls" "this" {
  bucket = aws_s3_bucket.this.id

  rule {
    object_ownership = "BucketOwnerEnforced"
  }
}

resource "aws_s3_bucket_public_access_block" "this" {
  bucket = aws_s3_bucket.this.id

  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true
}

resource "aws_s3_bucket_versioning" "this" {
  bucket = aws_s3_bucket.this.id

  versioning_configuration {
    status = var.versioning_enabled ? "Enabled" : "Suspended"
  }
}

resource "aws_s3_bucket_server_side_encryption_configuration" "this" {
  bucket = aws_s3_bucket.this.id

  rule {
    bucket_key_enabled = var.kms_key_arn == null ? false : var.bucket_key_enabled

    apply_server_side_encryption_by_default {
      sse_algorithm     = var.kms_key_arn == null ? "AES256" : "aws:kms"
      kms_master_key_id = var.kms_key_arn
    }
  }
}

resource "aws_s3_bucket_logging" "this" {
  count = var.access_log_target_bucket == null ? 0 : 1

  bucket        = aws_s3_bucket.this.id
  target_bucket = var.access_log_target_bucket
  target_prefix = var.access_log_target_prefix
}

resource "aws_s3_bucket_lifecycle_configuration" "this" {
  count = var.enable_lifecycle_policy ? 1 : 0

  bucket = aws_s3_bucket.this.id

  rule {
    id     = "storage-hygiene"
    status = "Enabled"

    filter {}

    abort_incomplete_multipart_upload {
      days_after_initiation = var.abort_incomplete_multipart_upload_days
    }

    dynamic "noncurrent_version_expiration" {
      for_each = var.noncurrent_version_expiration_days == null ? [] : [var.noncurrent_version_expiration_days]
      content {
        noncurrent_days = noncurrent_version_expiration.value
      }
    }

    dynamic "expiration" {
      for_each = var.object_expiration_days == null ? [] : [var.object_expiration_days]
      content {
        days = expiration.value
      }
    }
  }

  depends_on = [aws_s3_bucket_versioning.this]

  lifecycle {
    precondition {
      condition     = var.versioning_enabled || var.noncurrent_version_expiration_days == null
      error_message = "noncurrent_version_expiration_days requires versioning_enabled."
    }
  }
}

data "aws_iam_policy_document" "bucket" {
  statement {
    sid       = "DenyInsecureTransport"
    effect    = "Deny"
    actions   = ["s3:*"]
    resources = [aws_s3_bucket.this.arn, "${aws_s3_bucket.this.arn}/*"]

    principals {
      type        = "*"
      identifiers = ["*"]
    }

    condition {
      test     = "Bool"
      variable = "aws:SecureTransport"
      values   = ["false"]
    }
  }

  dynamic "statement" {
    for_each = length(var.allowed_reader_principal_arns) > 0 ? [1] : []
    content {
      sid       = "ExplicitReadersBucket"
      effect    = "Allow"
      actions   = ["s3:GetBucketLocation", "s3:ListBucket"]
      resources = [aws_s3_bucket.this.arn]
      principals {
        type        = "AWS"
        identifiers = sort(tolist(var.allowed_reader_principal_arns))
      }
    }
  }

  dynamic "statement" {
    for_each = length(var.allowed_reader_principal_arns) > 0 ? [1] : []
    content {
      sid       = "ExplicitReadersObjects"
      effect    = "Allow"
      actions   = ["s3:GetObject", "s3:GetObjectVersion"]
      resources = ["${aws_s3_bucket.this.arn}/*"]
      principals {
        type        = "AWS"
        identifiers = sort(tolist(var.allowed_reader_principal_arns))
      }
    }
  }

  dynamic "statement" {
    for_each = length(var.allowed_writer_principal_arns) > 0 ? [1] : []
    content {
      sid       = "ExplicitWritersBucket"
      effect    = "Allow"
      actions   = ["s3:GetBucketLocation", "s3:ListBucket", "s3:ListBucketMultipartUploads"]
      resources = [aws_s3_bucket.this.arn]
      principals {
        type        = "AWS"
        identifiers = sort(tolist(var.allowed_writer_principal_arns))
      }
    }
  }

  dynamic "statement" {
    for_each = length(var.allowed_writer_principal_arns) > 0 ? [1] : []
    content {
      sid    = "ExplicitWritersObjects"
      effect = "Allow"
      actions = [
        "s3:AbortMultipartUpload",
        "s3:DeleteObject",
        "s3:GetObject",
        "s3:GetObjectVersion",
        "s3:ListMultipartUploadParts",
        "s3:PutObject"
      ]
      resources = ["${aws_s3_bucket.this.arn}/*"]
      principals {
        type        = "AWS"
        identifiers = sort(tolist(var.allowed_writer_principal_arns))
      }
    }
  }
}

resource "aws_s3_bucket_policy" "this" {
  bucket = aws_s3_bucket.this.id
  policy = data.aws_iam_policy_document.bucket.json

  depends_on = [aws_s3_bucket_public_access_block.this]
}
