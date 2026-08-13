# AWS ECR Repository

Creates a private Amazon Elastic Container Registry repository with immutable
tags, scan-on-push, encryption, and bounded image retention by default. Optional
repository-policy inputs support explicit cross-account build and runtime roles
without granting anonymous access.

## Architecture

- one private ECR repository;
- ECR-managed AES-256 encryption or an optional customer-managed KMS key;
- basic vulnerability scanning requested on every push by default;
- lifecycle rules that expire old untagged images and cap total image count;
- optional cross-account pull and push/pull repository-policy statements.

## Prerequisites and usage

```bash
aws sts get-caller-identity
cp example.tfvars terraform.tfvars
tofu init
tofu plan
tofu apply

aws ecr get-login-password --region us-east-1 \
  | docker login --username AWS --password-stdin \
    "$(tofu output -raw repository_url | cut -d/ -f1)"
```

AWS credentials can come from environment variables, a shared profile, workload
identity, or another standard AWS provider credential source. Docker login
tokens expire, so CI should obtain a token per job instead of storing one.

## Important flags

| Flag | Default | Impact |
|---|---:|---|
| `image_tag_mutability` | `IMMUTABLE` | Prevents a released tag from silently pointing to different image content |
| `scan_on_push` | `true` | Requests basic vulnerability scanning on newly pushed images |
| `kms_key_arn` | `null` | Uses ECR-managed AES-256; a customer key adds policy control and KMS cost |
| `enable_lifecycle_policy` | `true` | Bounds storage growth but permanently expires images matching the rules |
| `untagged_retention_days` | `14` | Retains untagged build artifacts for rollback/debugging before expiration |
| `max_image_count` | `50` | Caps total tagged and untagged images after the age rule is evaluated |
| `force_delete` | `false` | Blocks destroy while images remain; enabling it permits destructive cleanup |
| `allowed_*_principal_arns` | `[]` | Adds cross-account data-plane permissions for only the named IAM principals |

## Image promotion and retention

Push immutable, content-addressed build tags such as a Git SHA and deploy image
digests where practical. `IMMUTABLE` protects existing tags; change to `MUTABLE`
only when a deliberate floating-tag workflow (for example `dev`) outweighs the
auditability and rollback risk.

The lifecycle policy first expires untagged images older than
`untagged_retention_days`, then expires the oldest images beyond
`max_image_count`. Lifecycle expiration is asynchronous and permanent. Set the
limits above the number needed for rollback, investigations, and release
retention. Disable the policy when another system owns repository lifecycle.

## Scanning and supply-chain security

Scan-on-push requests ECR basic scanning but does not block a deployment.
Delivery pipelines should inspect scan findings and enforce an organization
policy before promotion. Enhanced scanning, continuous rescans, signing,
provenance, replication, and pull-through cache are registry/account-level or
pipeline concerns and are intentionally outside this repository template.

## Encryption and IAM

The default ECR-managed encryption avoids customer KMS administration and
request charges. When `kms_key_arn` is set, ensure its key policy permits ECR
and the provisioning identity; losing key access makes images unusable.

Same-account permissions normally belong on build/runtime IAM identities.
Repository policies are most useful for cross-account access. The pull list
grants only layer/image reads. The push list grants upload plus pull actions;
callers still need `ecr:GetAuthorizationToken` through an identity policy.
Avoid account-root principals unless every identity in that account should be
eligible under its own IAM policy.

## Inputs and outputs

Only `project_name` is required. Variables cover naming, region, tag
mutability, scanning, encryption, retention, deletion behavior, cross-account
principals, environment, and tags. See `variables.tf` for exact validation.

Outputs expose the repository name, ARN, URL, and owning registry ID. The URL
can be passed directly into ECS, Lambda container-image, or CI/CD stacks.

## Cost, operations, and destroy behavior

ECR charges primarily for stored image layers and data transfer. KMS keys and
requests, enhanced scanning, cross-region replication, and public-network
egress can add cost outside this template. Monitor repository size, image age,
scan findings, failed pushes/pulls, and lifecycle actions. Test that critical
release digests remain available before tightening retention.

With `force_delete = false`, `tofu destroy` fails while the repository contains
images. Delete or replicate required images first, then empty the repository.
Setting `force_delete = true` makes destroy remove the repository and every
stored image; treat that as an explicit destructive opt-in.
