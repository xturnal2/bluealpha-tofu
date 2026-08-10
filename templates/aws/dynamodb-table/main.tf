locals {
  name_prefix = "${var.project_name}-${var.environment}"
  table_name  = coalesce(var.table_name, "${local.name_prefix}-table")

  attribute_types = merge(
    var.attribute_types,
    { (var.hash_key) = var.hash_key_type },
    var.range_key == null ? {} : { (var.range_key) = var.range_key_type }
  )

  used_attribute_names = toset(concat(
    [var.hash_key],
    var.range_key == null ? [] : [var.range_key],
    [for index in values(var.global_secondary_indexes) : index.hash_key],
    [for index in values(var.global_secondary_indexes) : index.range_key if index.range_key != null],
    [for index in values(var.local_secondary_indexes) : index.range_key]
  ))

  projected_attribute_count = sum(concat(
    [0],
    [for index in values(var.global_secondary_indexes) : length(index.non_key_attributes)],
    [for index in values(var.local_secondary_indexes) : length(index.non_key_attributes)]
  ))

  common_tags = merge({
    Environment = var.environment
    ManagedBy   = "OpenTofu"
    Project     = var.project_name
    Template    = "aws-dynamodb-table"
  }, var.tags)
}

resource "aws_dynamodb_table" "this" {
  name                        = local.table_name
  billing_mode                = var.billing_mode
  hash_key                    = var.hash_key
  range_key                   = var.range_key
  read_capacity               = var.billing_mode == "PROVISIONED" ? var.read_capacity : null
  write_capacity              = var.billing_mode == "PROVISIONED" ? var.write_capacity : null
  table_class                 = var.table_class
  deletion_protection_enabled = var.deletion_protection_enabled
  stream_enabled              = var.stream_enabled
  stream_view_type            = var.stream_enabled ? var.stream_view_type : null
  tags                        = local.common_tags

  dynamic "attribute" {
    for_each = local.attribute_types
    content {
      name = attribute.key
      type = attribute.value
    }
  }

  dynamic "global_secondary_index" {
    for_each = var.global_secondary_indexes
    content {
      name               = global_secondary_index.key
      hash_key           = global_secondary_index.value.hash_key
      range_key          = global_secondary_index.value.range_key
      projection_type    = global_secondary_index.value.projection_type
      non_key_attributes = global_secondary_index.value.non_key_attributes
      read_capacity = var.billing_mode == "PROVISIONED" ? coalesce(
        global_secondary_index.value.read_capacity,
        var.read_capacity
      ) : null
      write_capacity = var.billing_mode == "PROVISIONED" ? coalesce(
        global_secondary_index.value.write_capacity,
        var.write_capacity
      ) : null
    }
  }

  dynamic "local_secondary_index" {
    for_each = var.local_secondary_indexes
    content {
      name               = local_secondary_index.key
      range_key          = local_secondary_index.value.range_key
      projection_type    = local_secondary_index.value.projection_type
      non_key_attributes = local_secondary_index.value.non_key_attributes
    }
  }

  point_in_time_recovery {
    enabled                 = var.point_in_time_recovery_enabled
    recovery_period_in_days = var.point_in_time_recovery_enabled ? var.recovery_period_in_days : null
  }

  server_side_encryption {
    enabled     = true
    kms_key_arn = var.kms_key_arn
  }

  ttl {
    enabled        = var.ttl_enabled
    attribute_name = var.ttl_attribute_name
  }

  lifecycle {
    precondition {
      condition     = var.range_key == null || var.range_key != var.hash_key
      error_message = "range_key must differ from hash_key."
    }
    precondition {
      condition = (
        length(setsubtract(toset(keys(local.attribute_types)), local.used_attribute_names)) == 0 &&
        length(setsubtract(local.used_attribute_names, toset(keys(local.attribute_types)))) == 0
      )
      error_message = "attribute_types must declare every secondary-index key and no attributes that are not table/index keys."
    }
    precondition {
      condition     = length(var.global_secondary_indexes) <= 20
      error_message = "A table supports at most 20 global secondary indexes by default."
    }
    precondition {
      condition     = length(var.local_secondary_indexes) <= 5
      error_message = "A table supports at most 5 local secondary indexes."
    }
    precondition {
      condition     = length(var.local_secondary_indexes) == 0 || var.range_key != null
      error_message = "Local secondary indexes require a table range_key and must be planned at table creation."
    }
    precondition {
      condition     = local.projected_attribute_count <= 100
      error_message = "INCLUDE projections may name at most 100 attributes in total across all indexes."
    }
  }
}
