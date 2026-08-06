# AWS RDS PostgreSQL

Creates an encrypted PostgreSQL RDS instance in private subnets with explicit
client access, automated backups, AWS-managed master credentials, and deletion
protection by default.

## Architecture

- DB subnet group using at least two caller-provided private subnets;
- dedicated security group with no access until a security group or CIDR is
  explicitly allowed;
- encrypted gp3 storage with optional autoscaling and customer-managed KMS key;
- RDS-managed master password in Secrets Manager by default;
- automated backups, final snapshot, CloudWatch log exports, and optional
  Multi-AZ, Performance Insights, Enhanced Monitoring, and IAM authentication.

## Prerequisites and usage

```bash
cp example.tfvars terraform.tfvars
tofu init
tofu plan
tofu apply
```

Pass private subnet IDs from `aws/vpc` and the application security group from a
workload stack. The caller needs RDS, EC2 security group, IAM, KMS, CloudWatch,
and Secrets Manager permissions required by the selected flags.

## Important flags

| Flag | Default | Impact |
|---|---:|---|
| `manage_master_user_password` | `true` | Stores an RDS-generated password in Secrets Manager, which has a recurring secret charge |
| `multi_az` | `false` | Adds a synchronous standby and materially increases database cost |
| `publicly_accessible` | `false` | Keeps the endpoint private; public access still requires routing and explicit ingress |
| `backup_retention_days` | `7` | Controls point-in-time recovery history; zero disables automated backups |
| `deletion_protection` | `true` | Blocks destroy until deliberately disabled |
| `skip_final_snapshot` | `false` | Creates a final snapshot during destroy |
| `enable_performance_insights` | `false` | Adds performance telemetry and possible retention charges |
| `monitoring_interval_seconds` | `0` | Enables Enhanced Monitoring at the selected interval |
| `apply_immediately` | `false` | Defers eligible disruptive changes to the maintenance window |

For production, enable Multi-AZ, retain backups, pin `engine_version`, keep
deletion protection, and test restoration regularly.

## Credentials

With managed credentials, retrieve the secret ARN from
`master_user_secret_arn` and grant application identities only
`secretsmanager:GetSecretValue` plus KMS decrypt when applicable.

If `manage_master_user_password = false`, supply `master_password` through a
secure runtime input. It is still stored in OpenTofu state, so use an encrypted,
access-controlled remote backend. Never commit it in `.tfvars`.

## Inputs and outputs

Required inputs are `project_name`, `vpc_id`, and `subnet_ids`. Variables cover
client sources, engine version, instance/storage sizing, credentials, encryption,
availability, backups, deletion, maintenance, monitoring, authentication, logs,
and tags. See `variables.tf` for exact types and validation.

Outputs include instance IDs, hostname/endpoint/port, database name, security
group ID, and the optional RDS-managed secret ARN. No password is output.

## Cost, security, and destroy behavior

Instance runtime, provisioned storage, backup/snapshot storage, Multi-AZ,
Performance Insights, Enhanced Monitoring, Secrets Manager, and data transfer
are the primary costs. Storage encryption and security-group references are
enabled without opening broad network access.

Destroy requires `deletion_protection = false`. Unless
`skip_final_snapshot = true`, RDS creates `final_snapshot_identifier`; that name
must be unique in the region. Final snapshots and retained automated backups
continue to incur storage charges after the instance is gone.
