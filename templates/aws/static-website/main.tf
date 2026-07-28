data "aws_caller_identity" "current" {}

locals {
  name_prefix = "${var.project_name}-${var.environment}"
  name_hash   = substr(sha1("${data.aws_caller_identity.current.account_id}-${var.aws_region}-${local.name_prefix}"), 0, 12)

  origin_bucket_name = coalesce(
    var.site_bucket_name,
    "${substr(local.name_prefix, 0, 36)}-${local.name_hash}-site"
  )
  access_log_bucket_name = coalesce(
    var.log_bucket_name,
    "${substr(local.name_prefix, 0, 33)}-${local.name_hash}-cf-logs"
  )

  common_tags = merge(
    {
      Environment = var.environment
      ManagedBy   = "OpenTofu"
      Project     = var.project_name
      Template    = "aws-static-website"
    },
    var.tags
  )
}

resource "aws_s3_bucket" "site" {
  bucket        = local.origin_bucket_name
  force_destroy = var.force_destroy
  tags          = merge(local.common_tags, { Name = local.origin_bucket_name })
}

resource "aws_s3_bucket_public_access_block" "site" {
  bucket = aws_s3_bucket.site.id

  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true
}

resource "aws_s3_bucket_ownership_controls" "site" {
  bucket = aws_s3_bucket.site.id

  rule {
    object_ownership = "BucketOwnerEnforced"
  }
}

resource "aws_s3_bucket_server_side_encryption_configuration" "site" {
  bucket = aws_s3_bucket.site.id

  rule {
    apply_server_side_encryption_by_default {
      sse_algorithm = "AES256"
    }
  }
}

resource "aws_s3_bucket_versioning" "site" {
  bucket = aws_s3_bucket.site.id

  versioning_configuration {
    status = var.enable_versioning ? "Enabled" : "Suspended"
  }
}

resource "aws_s3_bucket_lifecycle_configuration" "site_versions" {
  count = var.enable_versioning && var.noncurrent_version_expiration_days > 0 ? 1 : 0

  bucket = aws_s3_bucket.site.id

  rule {
    id     = "expire-noncurrent-site-versions"
    status = "Enabled"

    filter {}

    noncurrent_version_expiration {
      noncurrent_days = var.noncurrent_version_expiration_days
    }
  }

  depends_on = [aws_s3_bucket_versioning.site]
}

resource "aws_s3_object" "sample_index" {
  count = var.create_sample_content ? 1 : 0

  bucket       = aws_s3_bucket.site.id
  key          = var.index_document
  content_type = "text/html; charset=utf-8"
  content      = <<-HTML
    <!doctype html>
    <html lang="en">
      <head>
        <meta charset="utf-8">
        <meta name="viewport" content="width=device-width">
        <title>${var.project_name}</title>
      </head>
      <body>
        <main>
          <h1>${var.project_name}</h1>
          <p>Deployed with the BlueAlpha AWS static website template.</p>
        </main>
      </body>
    </html>
  HTML

  depends_on = [aws_s3_bucket_server_side_encryption_configuration.site]
}

resource "aws_cloudfront_origin_access_control" "site" {
  name                              = "${local.name_prefix}-site"
  description                       = "Private S3 access for ${local.name_prefix}"
  origin_access_control_origin_type = "s3"
  signing_behavior                  = "always"
  signing_protocol                  = "sigv4"
}

resource "aws_cloudfront_cache_policy" "site" {
  name        = "${local.name_prefix}-site-cache"
  comment     = "Static asset caching for ${local.name_prefix}"
  min_ttl     = var.cache_min_ttl_seconds
  default_ttl = var.cache_default_ttl_seconds
  max_ttl     = var.cache_max_ttl_seconds

  parameters_in_cache_key_and_forwarded_to_origin {
    enable_accept_encoding_brotli = true
    enable_accept_encoding_gzip   = true

    cookies_config {
      cookie_behavior = "none"
    }

    headers_config {
      header_behavior = "none"
    }

    query_strings_config {
      query_string_behavior = var.forward_query_strings ? "all" : "none"
    }
  }
}

resource "aws_cloudfront_response_headers_policy" "security" {
  name    = "${local.name_prefix}-security-headers"
  comment = "Baseline browser security headers for ${local.name_prefix}"

  security_headers_config {
    content_type_options {
      override = true
    }

    frame_options {
      frame_option = "DENY"
      override     = true
    }

    referrer_policy {
      referrer_policy = "strict-origin-when-cross-origin"
      override        = true
    }

    strict_transport_security {
      access_control_max_age_sec = 31536000
      include_subdomains         = false
      preload                    = false
      override                   = true
    }

    xss_protection {
      mode_block = true
      protection = true
      override   = true
    }
  }
}

resource "aws_s3_bucket" "access_logs" {
  count = var.enable_access_logging ? 1 : 0

  provider = aws.logs

  bucket        = local.access_log_bucket_name
  force_destroy = var.force_destroy
  tags          = merge(local.common_tags, { Name = local.access_log_bucket_name })
}

resource "aws_s3_bucket_public_access_block" "access_logs" {
  count = var.enable_access_logging ? 1 : 0

  provider = aws.logs

  bucket = aws_s3_bucket.access_logs[0].id

  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = false
  restrict_public_buckets = true
}

resource "aws_s3_bucket_ownership_controls" "access_logs" {
  count = var.enable_access_logging ? 1 : 0

  provider = aws.logs

  bucket = aws_s3_bucket.access_logs[0].id

  rule {
    object_ownership = "BucketOwnerPreferred"
  }
}

resource "aws_s3_bucket_server_side_encryption_configuration" "access_logs" {
  count = var.enable_access_logging ? 1 : 0

  provider = aws.logs

  bucket = aws_s3_bucket.access_logs[0].id

  rule {
    apply_server_side_encryption_by_default {
      sse_algorithm = "AES256"
    }
  }
}

resource "aws_s3_bucket_lifecycle_configuration" "access_logs" {
  count = var.enable_access_logging ? 1 : 0

  provider = aws.logs

  bucket = aws_s3_bucket.access_logs[0].id

  rule {
    id     = "expire-cloudfront-access-logs"
    status = "Enabled"

    filter {
      prefix = "cloudfront/"
    }

    expiration {
      days = var.log_retention_days
    }
  }
}

resource "aws_cloudfront_distribution" "site" {
  enabled             = true
  is_ipv6_enabled     = var.enable_ipv6
  http_version        = "http2and3"
  comment             = "${local.name_prefix} static website"
  default_root_object = var.index_document
  aliases             = var.aliases
  price_class         = var.price_class
  web_acl_id          = var.web_acl_id
  wait_for_deployment = true

  origin {
    domain_name              = aws_s3_bucket.site.bucket_regional_domain_name
    origin_id                = "s3-${aws_s3_bucket.site.id}"
    origin_access_control_id = aws_cloudfront_origin_access_control.site.id
  }

  default_cache_behavior {
    allowed_methods            = ["GET", "HEAD", "OPTIONS"]
    cached_methods             = ["GET", "HEAD", "OPTIONS"]
    target_origin_id           = "s3-${aws_s3_bucket.site.id}"
    viewer_protocol_policy     = "redirect-to-https"
    compress                   = true
    cache_policy_id            = aws_cloudfront_cache_policy.site.id
    response_headers_policy_id = aws_cloudfront_response_headers_policy.security.id
  }

  dynamic "custom_error_response" {
    for_each = var.enable_spa_fallback ? toset([403, 404]) : toset([])

    content {
      error_code            = custom_error_response.value
      response_code         = 200
      response_page_path    = "/${var.index_document}"
      error_caching_min_ttl = 0
    }
  }

  dynamic "logging_config" {
    for_each = var.enable_access_logging ? [1] : []

    content {
      bucket          = aws_s3_bucket.access_logs[0].bucket_domain_name
      include_cookies = false
      prefix          = "cloudfront/"
    }
  }

  restrictions {
    geo_restriction {
      restriction_type = "none"
    }
  }

  viewer_certificate {
    acm_certificate_arn            = length(var.aliases) > 0 ? var.acm_certificate_arn : null
    cloudfront_default_certificate = length(var.aliases) == 0
    minimum_protocol_version       = length(var.aliases) > 0 ? "TLSv1.2_2021" : "TLSv1"
    ssl_support_method             = length(var.aliases) > 0 ? "sni-only" : null
  }

  tags = merge(local.common_tags, { Name = "${local.name_prefix}-site" })

  lifecycle {
    precondition {
      condition     = length(var.aliases) == 0 || var.acm_certificate_arn != null
      error_message = "acm_certificate_arn is required when aliases is non-empty."
    }

    precondition {
      condition = (
        var.cache_min_ttl_seconds <= var.cache_default_ttl_seconds &&
        var.cache_default_ttl_seconds <= var.cache_max_ttl_seconds
      )
      error_message = "Cache TTL values must satisfy min <= default <= max."
    }
  }

  depends_on = [
    aws_s3_bucket_ownership_controls.access_logs,
    aws_s3_bucket_public_access_block.access_logs,
    aws_s3_bucket_server_side_encryption_configuration.access_logs,
  ]
}

data "aws_iam_policy_document" "site" {
  statement {
    sid     = "AllowCloudFrontReadOnly"
    actions = ["s3:GetObject"]
    resources = [
      "${aws_s3_bucket.site.arn}/*",
    ]

    principals {
      type        = "Service"
      identifiers = ["cloudfront.amazonaws.com"]
    }

    condition {
      test     = "StringEquals"
      variable = "AWS:SourceArn"
      values   = [aws_cloudfront_distribution.site.arn]
    }
  }

  statement {
    sid = "DenyInsecureTransport"
    actions = [
      "s3:*",
    ]
    resources = [
      aws_s3_bucket.site.arn,
      "${aws_s3_bucket.site.arn}/*",
    ]

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
}

resource "aws_s3_bucket_policy" "site" {
  bucket = aws_s3_bucket.site.id
  policy = data.aws_iam_policy_document.site.json

  depends_on = [aws_s3_bucket_public_access_block.site]
}
