# AWS S3 Bucket

Creates a private general-purpose Amazon S3 bucket with enforced ownership,
complete public-access blocking, encryption, TLS-only access, versioning, and
storage-hygiene lifecycle rules by default.

## Architecture

- one globally unique general-purpose S3 bucket;
- Bucket owner enforced object ownership with ACLs disabled;
- all four bucket-level public-access-block settings enabled;
- S3-managed AES-256 or optional customer-managed KMS encryption;
- versioning and 90-day noncurrent-version retention by default;
- incomplete multipart upload cleanup, optional current-object expiration, and
  optional delivery of server access logs to an existing bucket;
- optional explicit reader and writer bucket-policy principals.

## Usage

```bash
aws sts get-caller-identity
cp example.tfvars terraform.tfvars
tofu init
tofu plan
tofu apply
aws s3api head-bucket --bucket "$(tofu output -raw bucket_name)"
```

The generated name uses the project, environment, and a random suffix. Set
`bucket_name` only when a stable globally unique name is required.

## Important flags

| Flag | Default | Impact |
|---|---:|---|
| `force_destroy` | `false` | Blocks destroy while any object/version remains; enabling permits permanent bulk deletion |
| `versioning_enabled` | `true` | Preserves overwritten/deleted object versions and increases storage usage |
| `kms_key_arn` | `null` | Uses S3-managed encryption; a customer key adds policy control and KMS cost |
| `bucket_key_enabled` | `true` | Reduces KMS requests when customer-managed encryption is selected |
| `enable_lifecycle_policy` | `true` | Enables multipart cleanup and configured expiration behavior |
| `noncurrent_version_expiration_days` | `90` | Permanently expires recovery versions after the configured age |
| `object_expiration_days` | `null` | Non-null values permanently expire current objects after that age |
| `access_log_target_bucket` | `null` | Sends server access logs to an existing, separately secured log bucket |
| `allowed_*_principal_arns` | `[]` | Adds explicit data access; identity policies can be used for same-account roles instead |

## Access model

The bucket is private and ACLs are disabled. Public ACLs and policies are
blocked, and a bucket policy denies every request that does not use TLS. These
controls complement, but do not replace, account-level S3 Public Access Block
and organization policies.

Same-account workloads can use identity policies scoped to the bucket and
object ARNs. Resource-policy readers receive list/location and object reads.
Writers additionally receive object write/delete and multipart actions, but not
bucket administration or policy changes. For customer-managed encryption,
principals also need matching KMS permissions and the key policy must trust them.

Use access points or a workload-specific policy when prefixes, VPC endpoints,
organizations, source accounts, service principals, or conditional writes need
different boundaries.

## Versioning and lifecycle

Versioning protects against accidental overwrites and deletes, but it is not a
separate backup or immutable retention control. The default lifecycle expires
noncurrent versions after 90 days and aborts incomplete multipart uploads after
7 days. Both actions are asynchronous and permanent.

Set `noncurrent_version_expiration_days = null` for indefinite version
retention. `object_expiration_days` is null by default because generic business
data should not be deleted without a retention decision. Object Lock, legal
holds, replication, archival transitions, and backup plans are workload-specific
and intentionally not hidden behind unsafe generic defaults.

## Encryption and logging

S3-managed AES-256 is the low-administration encrypted default. A customer KMS
key supports centralized key policy and audit controls; enabling an S3 Bucket
Key reduces request volume but changes the KMS encryption context applications
may inspect.

Server access logging requires an existing destination bucket configured to
accept S3 log delivery. Do not target this bucket itself. Centralize logs in a
separate account or bucket with retention and restricted readers. CloudTrail S3
data events provide API-level auditing but are configured outside this stack.

## Inputs and outputs

Only `project_name` is required. Variables cover naming, deletion, versioning,
encryption, lifecycle, logging, explicit principals, region, environment, and
tags. Outputs expose the bucket name/ARN, regional hostname, and region.

## Cost, monitoring, and destroy behavior

Storage by class, requests, versions, lifecycle transitions, replication,
retrieval, data transfer, logs, and KMS drive cost. Monitor bucket size and
object count by version class, 4xx/5xx errors, denied requests, incomplete
uploads, lifecycle actions, replication status, and unusual access.

With `force_destroy = false`, `tofu destroy` fails until all current objects,
versions, and delete markers are removed. This is intentional. Inventory and
preserve required data, empty the bucket deliberately, then destroy. Enabling
`force_destroy` authorizes the provider to permanently remove all content.
