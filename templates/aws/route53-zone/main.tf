locals {
  common_tags = merge(var.tags, {
    Environment = var.environment
    ManagedBy   = "OpenTofu"
    Project     = var.project_name
    Template    = "aws/route53-zone"
  })
}

resource "aws_route53_zone" "this" {
  name              = trimsuffix(lower(var.zone_name), ".")
  comment           = var.comment
  delegation_set_id = var.private_zone ? null : var.delegation_set_id
  force_destroy     = var.force_destroy
  tags              = local.common_tags

  dynamic "vpc" {
    for_each = var.private_zone ? var.vpc_associations : {}

    content {
      vpc_id     = vpc.value.vpc_id
      vpc_region = vpc.value.vpc_region
    }
  }

  lifecycle {
    precondition {
      condition     = var.private_zone == (length(var.vpc_associations) > 0)
      error_message = "Private zones require at least one VPC association; public zones require none."
    }
    precondition {
      condition     = !var.private_zone || var.delegation_set_id == null
      error_message = "delegation_set_id applies only to public hosted zones."
    }
  }
}

resource "aws_route53_record" "standard" {
  for_each = var.records

  zone_id         = aws_route53_zone.this.zone_id
  name            = each.value.name
  type            = upper(each.value.type)
  ttl             = each.value.ttl
  records         = each.value.values
  allow_overwrite = each.value.allow_overwrite
}

resource "aws_route53_record" "alias" {
  for_each = var.alias_records

  zone_id         = aws_route53_zone.this.zone_id
  name            = each.value.name
  type            = upper(each.value.type)
  allow_overwrite = each.value.allow_overwrite

  alias {
    name                   = each.value.target_name
    zone_id                = each.value.target_zone_id
    evaluate_target_health = each.value.evaluate_target_health
  }
}
