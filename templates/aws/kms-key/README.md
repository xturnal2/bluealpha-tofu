# AWS KMS Key

Creates a symmetric customer-managed AWS KMS encryption key with an alias,
automatic rotation, a 30-day deletion window, account IAM enablement, and
optional explicit administrators and cryptographic users.

## Architecture

- one regional or multi-Region primary symmetric encryption key;
- stable `alias/<project>-<environment>` by default;
- automatic 365-day key-material rotation;
- account-root policy statement that enables IAM delegation;
- optional key-policy administrators and encrypt/decrypt users.

## Usage

```bash
aws sts get-caller-identity
cp example.tfvars terraform.tfvars
tofu init
tofu plan
tofu apply
aws kms describe-key --key-id "$(tofu output -raw key_arn)"
```

## Important flags

| Flag | Default | Impact |
|---|---:|---|
| `enable_key_rotation` | `true` | Rotates AWS-generated symmetric key material automatically |
| `rotation_period_in_days` | `365` | Controls rotation cadence from 90-2560 days |
| `deletion_window_in_days` | `30` | Maximum waiting period to cancel accidental scheduled deletion |
| `multi_region` | `false` | Creates a multi-Region primary; replicas and their lifecycle require separate management |
| `allowed_key_administrator_arns` | `[]` | Adds key administration without granting cryptographic data access by itself |
| `allowed_cryptographic_user_arns` | `[]` | Adds encrypt/decrypt/data-key access without policy or deletion administration |

## Policy and separation of duties

The account-root statement enables IAM policies in the owning account to grant
access. Explicit principal lists are useful for cross-account or centrally
governed access. Cryptographic users cannot administer or delete the key.
Administrators can manage configuration and policy but are not granted
`ScheduleKeyDeletion` by the explicit statement; account authorities can still
delegate it through IAM because the root enablement statement is present.

Key policies are security boundaries and easy to make unrecoverable. Keep a
tested break-glass administration path, avoid deleting the root IAM-enablement
statement, and review every cross-account principal. Service integrations may
need service principals, grants, encryption-context conditions, or `kms:ViaService`
conditions that should be composed for the specific workload.

## Rotation and multi-Region keys

Automatic rotation creates new backing key material while preserving the key ID
and old material for decryption. It does not re-encrypt existing data or rotate
application secrets. Verify each integrated service supports customer-managed
keys and monitor grants and authorization failures.

Multi-Region keys share key material across explicitly created replicas but are
not a global service endpoint. Replicas add regional cost and policy/lifecycle
complexity. This stack creates only the primary; add replicas in regional root
configurations with a coordinated deletion and failover plan.

## Inputs and outputs

Only `project_name` is required. Variables cover alias, description, rotation,
deletion, multi-Region behavior, administrators, cryptographic users, region,
environment, and tags. Outputs expose key/alias IDs and ARNs only.

## Cost, monitoring, and destroy behavior

Each key (and multi-Region replica) has monthly cost; cryptographic requests and
some integrations add usage cost. Monitor denied operations, key disablement,
policy/grant changes, rotation status, unusual decrypt volume, and deletion
scheduling through CloudTrail and security tooling.

Destroy schedules key deletion for `deletion_window_in_days`; encrypted data
becomes permanently unrecoverable after deletion. Inventory every dependency,
retain required decrypt capability, disable and observe before deletion, and
cancel deletion immediately if scheduled accidentally.
