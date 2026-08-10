# AWS DynamoDB Table

Creates an encrypted Amazon DynamoDB table with on-demand billing, point-in-time
recovery, and deletion protection by default. The template supports composite
keys, TTL, streams, provisioned capacity, and map-driven global/local secondary
indexes while validating that key attribute declarations remain consistent.

## Architecture

- one DynamoDB table with a string partition key by default;
- DynamoDB-owned encryption key or an optional customer-managed KMS key;
- continuous point-in-time recovery with a configurable 1-35 day window;
- deletion protection enabled by default;
- optional TTL and DynamoDB Streams;
- optional global and local secondary indexes with projection and provisioned
  capacity controls.

## Prerequisites and usage

```bash
aws sts get-caller-identity
cp example.tfvars terraform.tfvars
tofu init
tofu plan
tofu apply
aws dynamodb describe-table --table-name "$(tofu output -raw table_name)"
```

AWS credentials can come from environment variables, a shared profile, workload
identity, or another standard AWS provider credential source.

## Important flags

| Flag | Default | Impact |
|---|---:|---|
| `billing_mode` | `PAY_PER_REQUEST` | Scales without capacity planning; provisioned can cost less for predictable traffic |
| `read_capacity` / `write_capacity` | `5` | Applied only in PROVISIONED mode and require workload-specific sizing |
| `table_class` | `STANDARD` | Infrequent Access shifts the storage/request price tradeoff |
| `deletion_protection_enabled` | `true` | Blocks deletion and must be disabled before intentional destroy |
| `point_in_time_recovery_enabled` | `true` | Keeps continuous recovery points and adds backup cost |
| `recovery_period_in_days` | `35` | Controls the available PITR window, not PITR pricing |
| `kms_key_arn` | `null` | Selects a customer-managed key instead of DynamoDB-owned encryption |
| `ttl_enabled` | `false` | Asynchronously expires items using epoch seconds in `ttl_attribute_name` |
| `stream_enabled` | `false` | Emits change records for event-driven consumers |
| `global_secondary_indexes` | `{}` | Adds alternate access patterns with storage/write cost |
| `local_secondary_indexes` | `{}` | Adds immutable alternate sort keys and 10-GiB item-collection constraints |

## Key and index model

Choose access patterns before creating the table. `hash_key` is the partition
key and optional `range_key` is the sort key. Key values must use scalar `S`,
`N`, or `B` types. DynamoDB is otherwise schemaless: do not declare ordinary
non-key item attributes in `attribute_types`.

Every secondary-index key that is not already a table key must appear in
`attribute_types`. The template verifies that all declared attributes are used
as keys and all index keys have types. It also checks the default quotas of 20
global and 5 local secondary indexes plus the 100-attribute INCLUDE projection
limit. AWS documents the current [secondary-index guidance and constraints](https://docs.aws.amazon.com/amazondynamodb/latest/developerguide/bp-indexes-general.html).

Global secondary indexes can use a different partition key and are eventually
consistent. Their writes consume additional capacity/cost and can back-pressure
base-table writes when underprovisioned. In PROVISIONED mode, omitted GSI
capacity inherits the table's configured capacity.

Local secondary indexes share the table partition key, require a base-table sort
key, and can only be created with the table. Adding, removing, or changing an
LSI therefore requires replacement and risks data loss. Each partition-key item
collection with LSIs has a 10-GiB limit.

## Recovery and deletion protection

Point-in-time recovery is enabled with the full 35-day window by default. AWS
prices PITR based on protected table/index size rather than the configured
window; see the [DynamoDB PITR documentation](https://docs.aws.amazon.com/amazondynamodb/latest/developerguide/Point-in-time-recovery.html).
Restoring creates a separate table and is not an in-place rollback, so test
restore procedures and application cutover.

Deletion protection blocks `tofu destroy`. To intentionally remove the table,
first set `deletion_protection_enabled = false`, apply that change, verify any
required backup/export, and then destroy. This deliberate two-step operation
reduces accidental deletion risk.

## TTL and streams

When TTL is enabled, applications write `ttl_attribute_name` as a Number holding
Unix epoch time in seconds. Expiration is asynchronous, so applications must not
assume an expired item disappears immediately and should filter it when needed.
AWS describes the current [TTL behavior](https://docs.aws.amazon.com/amazondynamodb/latest/developerguide/TTL.html).

Streams capture item changes for Lambda or other consumers. Choose the smallest
`stream_view_type` that meets the consumer's needs to reduce payload and data
exposure. Enabling or changing the stream produces a new stream descriptor;
downstream event-source mappings should consume output `stream_arn`.

## Encryption and IAM

DynamoDB encrypts the table, indexes, streams, and backups at rest. Null
`kms_key_arn` uses a DynamoDB-owned key without KMS request charges. A
customer-managed key gives policy and rotation control but adds KMS cost and
requires key policy permissions for DynamoDB and caller roles. AWS documents
the supported [DynamoDB encryption options](https://docs.aws.amazon.com/amazondynamodb/latest/developerguide/EncryptionAtRest.html).

The stack creates no application identity or resource policy. Grant application
roles only the table/index/stream actions they need, and include index ARNs when
querying GSIs. Keep scan, PartiQL, backup, export, and administrative actions
separate from normal read/write roles.

## Inputs and outputs

Only `project_name` is required. Variables cover naming, primary keys, billing
and capacity, index definitions, table class, protection/recovery, KMS, TTL,
streams, region, environment, and tags. See `variables.tf` for exact types and
validation.

Outputs include the table name/ID/ARN, nullable stream identifiers, and sorted
global/local index names.

## Cost, monitoring, and destroy behavior

Reads, writes, storage, indexes, streams, backups, exports, data transfer, and
optional KMS requests drive cost. Monitor consumed/throttled capacity, request
latency, system/user errors, conditional-check failures, table/index size, GSI
back pressure, stream iterator age, and account-level on-demand limits.

With deletion protection disabled, `tofu destroy` permanently deletes the table
and all items. PITR recovery points tied to the deleted table do not replace a
deliberate retention/export plan. Preserve or restore-test required data before
destructive changes.
