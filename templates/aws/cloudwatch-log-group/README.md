# AWS CloudWatch log group

Creates a deliberately managed CloudWatch Logs log group for application,
service, or audit logs. The template defaults to 30-day retention and deletion
protection so logs do not grow forever or disappear during an accidental
destroy.

## Architecture

- One explicitly named CloudWatch log group.
- Configurable finite retention.
- AWS-managed encryption by default, with an optional symmetric customer KMS
  key.
- `STANDARD` and `INFREQUENT_ACCESS` log classes.
- Deletion protection enabled by default.

Log producers, metric filters, subscription filters, resource policies, and
destinations remain outside this stack. This keeps the log storage lifecycle
independent from each workload that writes to it.

## Prerequisites and authentication

- OpenTofu 1.8 or newer.
- AWS credentials with permission to manage CloudWatch log groups and their
  tags.
- When `kms_key_arn` is set, the key policy must allow the regional CloudWatch
  Logs service to use the key and the deploying principal to associate it.

The AWS provider uses the normal environment, shared configuration, workload
identity, or instance-role credential chain. Do not place credentials in
`terraform.tfvars`.

## Usage

```bash
cp example.tfvars terraform.tfvars
tofu init
tofu plan
tofu apply
```

Point a workload's logging configuration at the `log_group_name` output. A
custom name is useful when a service expects a conventional path such as
`/aws/ecs/example`.

## Important inputs

| Input | Default | Purpose |
|---|---:|---|
| `log_group_name` | generated path | Overrides `/project/environment/application`. |
| `retention_in_days` | `30` | Limits retained log history to a supported CloudWatch period. |
| `log_group_class` | `STANDARD` | Selects full features or infrequent-access economics. |
| `kms_key_arn` | `null` | Uses a customer-managed symmetric KMS key. |
| `deletion_protection_enabled` | `true` | Blocks API and OpenTofu deletion until disabled. |
| `skip_destroy` | `false` | Retains the group but removes it from state during destroy. |

## Cost considerations

CloudWatch Logs charges for ingestion, storage, analysis, exports, and some data
transfers. Retention is the main long-term cost control. A KMS key has its own
monthly and request charges. `INFREQUENT_ACCESS` can suit high-volume logs that
are queried rarely, but it supports fewer CloudWatch Logs features; confirm
downstream feature compatibility before selecting it.

## Security and operations

- Keep deletion protection enabled for production and audit logs.
- Use a customer-managed KMS key when separation of duties, revocation, or key
  policy control is required.
- Grant writers only the log-stream and event permissions they need; this
  template does not broaden workload IAM permissions.
- Alarm on rejected log deliveries and periodically review retention against
  incident-response and compliance requirements.
- `skip_destroy = true` intentionally leaves an unmanaged cloud resource after
  it is removed from state. Use it only when another owner will import it.

## Outputs

The stack returns the log group ARN, name, and configured class. It does not
return keys, credentials, or log content.

## Destroy behavior

The default destroy is blocked by deletion protection. Set
`deletion_protection_enabled = false`, apply that change, and then destroy when
deletion is intentional. CloudWatch permanently deletes stored events with the
group. If `skip_destroy = true`, OpenTofu forgets the group instead; record and
transfer ownership before doing this.
