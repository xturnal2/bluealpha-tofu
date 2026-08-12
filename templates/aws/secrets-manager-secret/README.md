# AWS Secrets Manager Secret

Creates an AWS Secrets Manager secret boundary, optional regional replicas, and
an access policy without placing a secret value in OpenTofu configuration or
state. Deletion recovery is 30 days by default and public resource policies are
rejected.

## Architecture

- one primary Secrets Manager secret with metadata and tags;
- AWS-managed encryption or an optional customer-managed KMS key;
- optional cross-region replicas with regional KMS keys;
- optional read and value-management resource-policy principals;
- no `aws_secretsmanager_secret_version` and therefore no managed secret value.

## Usage

```bash
aws sts get-caller-identity
cp example.tfvars terraform.tfvars
tofu init
tofu plan
tofu apply

aws secretsmanager put-secret-value \
  --secret-id "$(tofu output -raw secret_arn)" \
  --secret-string file://secret.json
```

Use a protected CI secret, interactive operator workflow, or a purpose-built
rotation process for `secret.json`. Do not commit it or pass plaintext as a
command-line argument where shell history or process listings can expose it.

## Important flags

| Flag | Default | Impact |
|---|---:|---|
| `kms_key_id` | `null` | Uses `aws/secretsmanager`; a customer key adds control, policy obligations, and KMS cost |
| `recovery_window_in_days` | `30` | Delays permanent deletion and name reuse for 7-30 days |
| `replica_regions` | `{}` | Adds regional read availability, storage/KMS cost, and asynchronous replication |
| `force_overwrite_replica_secret` | `false` | Enabling permits a same-named destination secret to be overwritten during replication |
| `allowed_reader_principal_arns` | `[]` | Grants only describe and value-read actions to explicit principals |
| `allowed_writer_principal_arns` | `[]` | Grants secret-version and rotation management, but not secret deletion or policy administration |

## Why values are excluded

OpenTofu state records resource arguments, including values marked sensitive.
Managing `secret_string` or `secret_binary` would therefore copy the material
into every state version, backup, plan artifact, and system allowed to read
state. This template manages the durable secret identity and access boundary;
another controlled channel populates and rotates values.

Applications should retrieve the current version at runtime through an IAM role
and cache it only as long as appropriate. Never return secret values from
outputs. If another workflow chooses to manage secret versions with OpenTofu,
it must treat the backend and all plan/state artifacts as secret stores.

## IAM and KMS

Same-account access can be granted entirely with identity policies. Resource
policy inputs are useful for cross-account or centrally controlled access and
are validated by Secrets Manager with `block_public_policy = true`. Readers get
`DescribeSecret` and `GetSecretValue`; writers also manage versions and
rotation, but cannot delete the secret or change its policy.

A customer-managed KMS key needs key-policy permission for the workloads and
Secrets Manager path. IAM permission on the secret alone cannot decrypt a value.
Use a regional key for each replica and test access after replication.

## Replication and rotation

Replicas improve regional availability but replication is asynchronous. The
primary controls secret metadata and rotation; consumers should define their
regional fallback behavior and verify version convergence. A replica region
must not equal `aws_region`.

Rotation requires a service-specific Lambda function, network access, and a
rotation contract, so this generic boundary does not create one. Attach a tested
rotation workflow after deployment and alert on failed or overdue rotations.

## Inputs and outputs

Only `project_name` is required. Variables cover name/path, description,
encryption, recovery, replication, explicit principals, region, environment,
and tags. Outputs expose only the secret ARN/name and configured replica regions.

## Cost, monitoring, and destroy behavior

Secrets and replicas are billed monthly; API calls and customer-managed KMS
requests add usage cost. Monitor access denials, unusual reads, policy changes,
rotation failures, replica status, deletion scheduling, and restore activity
through CloudTrail and your security tooling.

`tofu destroy` schedules deletion using `recovery_window_in_days`; it does not
immediately purge the primary secret. Applications lose normal access while
deletion is pending, and the name cannot be reused until recovery or final
deletion. Replicas must be understood in the recovery plan. Restore promptly if
deletion was accidental.
