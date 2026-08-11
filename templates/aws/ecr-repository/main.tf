locals {
  repository_name = coalesce(var.repository_name, "${var.project_name}-${var.environment}")

  common_tags = merge({
    Environment = var.environment
    ManagedBy   = "OpenTofu"
    Project     = var.project_name
    Template    = "aws-ecr-repository"
  }, var.tags)
}

resource "aws_ecr_repository" "this" {
  name                 = local.repository_name
  image_tag_mutability = var.image_tag_mutability
  force_delete         = var.force_delete

  encryption_configuration {
    encryption_type = var.kms_key_arn == null ? "AES256" : "KMS"
    kms_key         = var.kms_key_arn
  }

  image_scanning_configuration {
    scan_on_push = var.scan_on_push
  }

  tags = local.common_tags
}

resource "aws_ecr_lifecycle_policy" "this" {
  count = var.enable_lifecycle_policy ? 1 : 0

  repository = aws_ecr_repository.this.name
  policy = jsonencode({
    rules = [
      {
        rulePriority = 1
        description  = "Expire untagged images after ${var.untagged_retention_days} days"
        selection = {
          tagStatus   = "untagged"
          countType   = "sinceImagePushed"
          countUnit   = "days"
          countNumber = var.untagged_retention_days
        }
        action = { type = "expire" }
      },
      {
        rulePriority = 2
        description  = "Retain no more than ${var.max_image_count} images"
        selection = {
          tagStatus   = "any"
          countType   = "imageCountMoreThan"
          countNumber = var.max_image_count
        }
        action = { type = "expire" }
      }
    ]
  })
}

data "aws_iam_policy_document" "repository" {
  count = length(var.allowed_pull_principal_arns) + length(var.allowed_push_principal_arns) > 0 ? 1 : 0

  dynamic "statement" {
    for_each = length(var.allowed_pull_principal_arns) > 0 ? [1] : []
    content {
      sid    = "CrossAccountPull"
      effect = "Allow"
      actions = [
        "ecr:BatchCheckLayerAvailability",
        "ecr:BatchGetImage",
        "ecr:GetDownloadUrlForLayer"
      ]

      principals {
        type        = "AWS"
        identifiers = sort(tolist(var.allowed_pull_principal_arns))
      }
    }
  }

  dynamic "statement" {
    for_each = length(var.allowed_push_principal_arns) > 0 ? [1] : []
    content {
      sid    = "CrossAccountPushPull"
      effect = "Allow"
      actions = [
        "ecr:BatchCheckLayerAvailability",
        "ecr:BatchGetImage",
        "ecr:CompleteLayerUpload",
        "ecr:GetDownloadUrlForLayer",
        "ecr:InitiateLayerUpload",
        "ecr:PutImage",
        "ecr:UploadLayerPart"
      ]

      principals {
        type        = "AWS"
        identifiers = sort(tolist(var.allowed_push_principal_arns))
      }
    }
  }
}

resource "aws_ecr_repository_policy" "this" {
  count = length(var.allowed_pull_principal_arns) + length(var.allowed_push_principal_arns) > 0 ? 1 : 0

  repository = aws_ecr_repository.this.name
  policy     = data.aws_iam_policy_document.repository[0].json
}
