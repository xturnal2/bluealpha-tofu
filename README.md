# BlueAlpha OpenTofu Templates

Production-minded, reusable [OpenTofu](https://opentofu.org/) stacks for common
cloud workloads.

The catalog starts with AWS and Azure and is designed to grow without making
users learn a custom wrapper. Every stack is a standalone root module with:

- secure defaults and explicit opt-ins for public access or recurring costs;
- a stack-specific README describing architecture, cost considerations, inputs,
  outputs, and operational notes;
- an `example.tfvars` file that can be copied and adapted;
- input validation and provider/version constraints;
- consistent tags and resource naming.

## Template catalog

The repository is being built incrementally so each stack has a focused review
and release history.

| Cloud | Stack | Description | Cost-sensitive flags |
|---|---|---|---|
| AWS | [VPC](templates/aws/vpc) | Multi-AZ VPC with public/private subnets and optional NAT gateways | `enable_nat_gateway`, `single_nat_gateway`, `enable_flow_logs` |
| AWS | [Static website](templates/aws/static-website) | Private S3 origin delivered through CloudFront with TLS | `enable_access_logging`, `enable_versioning`, `price_class` |
| AWS | [S3 bucket](templates/aws/s3-bucket) | Private encrypted object storage with versioning and lifecycle controls | `force_destroy`, `versioning_enabled`, `noncurrent_version_expiration_days` |
| AWS | [ECS Fargate service](templates/aws/ecs-fargate-service) | Container service behind an Application Load Balancer | `desired_count`, `use_fargate_spot`, `enable_autoscaling` |
| AWS | [RDS PostgreSQL](templates/aws/rds-postgresql) | Private encrypted PostgreSQL with backups and managed credentials | `multi_az`, `deletion_protection`, `backup_retention_days` |
| AWS | [Lambda HTTP API](templates/aws/lambda-api) | Packaged Lambda behind an HTTP API with logs and throttling | `memory_size`, `reserved_concurrent_executions`, `throttle_rate_limit` |
| AWS | [SQS queue](templates/aws/sqs-queue) | Encrypted queue with optional FIFO behavior and a restricted DLQ | `create_dead_letter_queue`, `fifo_queue`, `kms_master_key_id` |
| AWS | [SNS topic](templates/aws/sns-topic) | Encrypted pub/sub topic with filters, DLQs, and optional FIFO delivery | `fifo_topic`, `subscriptions`, `archive_policy_days` |
| AWS | [EventBridge bus](templates/aws/eventbridge-bus) | Custom event bus with scoped publishers and optional replay archive | `kms_key_identifier`, `enable_archive`, `allowed_put_events_principal_arns` |
| AWS | [DynamoDB table](templates/aws/dynamodb-table) | Serverless key-value table with recovery, TTL, streams, and indexes | `billing_mode`, `deletion_protection_enabled`, `point_in_time_recovery_enabled` |
| AWS | [ECR repository](templates/aws/ecr-repository) | Private container registry with immutable tags, scanning, and image retention | `image_tag_mutability`, `scan_on_push`, `max_image_count` |
| AWS | [Secrets Manager secret](templates/aws/secrets-manager-secret) | Metadata-only secret boundary with recovery, replicas, and scoped access | `recovery_window_in_days`, `replica_regions`, `allowed_reader_principal_arns` |
| AWS | [KMS key](templates/aws/kms-key) | Rotating symmetric encryption key with guarded deletion and scoped users | `rotation_period_in_days`, `deletion_window_in_days`, `multi_region` |
| AWS | [CloudWatch log group](templates/aws/cloudwatch-log-group) | Managed log retention with optional KMS encryption and deletion protection | `retention_in_days`, `log_group_class`, `deletion_protection_enabled` |
| AWS | [Route 53 hosted zone](templates/aws/route53-zone) | Public or VPC-private DNS zone with standard and AWS alias records | `private_zone`, `vpc_associations`, `force_destroy` |
| AWS | [IAM role](templates/aws/iam-role) | Explicit workload or cross-account trust with bounded permissions | `trusted_service_principals`, `permissions_boundary_arn`, `managed_policy_arns` |
| Azure | [Virtual network](templates/azure/vnet) | VNet with configurable subnets, NSGs, delegations, and optional NAT Gateway | `enable_nat_gateway`, `create_network_security_groups` |
| Azure | [Static website](templates/azure/static-website) | Storage static website with optional Front Door delivery | `enable_cdn`, `enable_versioning`, `account_replication_type` |
| Azure | [Storage Account](templates/azure/storage-account) | Entra-first private object storage with versioning, recovery, and network controls | `account_replication_type`, `shared_access_key_enabled`, `public_network_access_enabled` |
| Azure | [Container Apps](templates/azure/container-apps) | Consumption-scaled container app with ingress and logs | `min_replicas`, `max_replicas`, `external_ingress_enabled` |
| Azure | [PostgreSQL Flexible Server](templates/azure/postgresql-flexible) | Private managed PostgreSQL with DNS and backups | `sku_name`, `high_availability_mode`, `geo_redundant_backup_enabled` |
| Azure | [Functions HTTP](templates/azure/functions-http) | Linux Function App with storage, monitoring, and HTTP controls | `plan_sku_name`, `maximum_instance_count`, `ip_restrictions` |
| Azure | [Service Bus queue](templates/azure/service-bus-queue) | Entra-authenticated namespace and queue with DLQ behavior | `sku`, `premium_messaging_units`, `requires_session` |
| Azure | [Event Grid topic](templates/azure/event-grid-topic) | Entra-authenticated event fan-out with scoped publishers and subscriptions | `local_auth_enabled`, `allowed_ip_cidrs`, `event_subscriptions` |
| Azure | [Event Hubs](templates/azure/event-hubs) | Entra-authenticated event stream with partitions, retention, and consumer groups | `sku`, `partition_count`, `auto_inflate_enabled` |
| Azure | [Container Registry](templates/azure/container-registry) | Managed container registry with Entra RBAC and Premium network/resilience options | `sku`, `public_network_access_enabled`, `georeplications` |
| Azure | [Key Vault](templates/azure/key-vault) | RBAC-authorized secret boundary with recovery and network controls | `purge_protection_enabled`, `public_network_access_enabled`, `role_assignments` |
| Azure | [Managed identity](templates/azure/managed-identity) | User-assigned workload identity with OIDC federation and scoped RBAC | `federated_credentials`, `role_assignments`, `isolation_scope` |
| Azure | [Log Analytics workspace](templates/azure/log-analytics-workspace) | Entra-first log analytics with bounded ingestion and configurable retention | `daily_quota_gb`, `retention_in_days`, `internet_ingestion_enabled` |
| Azure | [DNS zone](templates/azure/dns-zone) | Public authoritative DNS with common records, Azure aliases, and scoped RBAC | `a_records`, `cname_records`, `soa_record` |

See the [roadmap](ROADMAP.md) for the planned AWS and Azure stacks and their
proposed delivery order.

## Connected architecture examples

| Cloud | Example | Composed stacks |
|---|---|---|
| AWS | [Connected application platform](examples/aws/connected-app-platform) | VPC, ECS Fargate, RDS PostgreSQL, SQS/DLQ, and DynamoDB |

Examples demonstrate output-to-input composition, cross-stack IAM, network
boundaries, and operational tradeoffs. They create multiple chargeable services;
review their READMEs and plans before applying.

## Quick start

Prerequisites:

- OpenTofu 1.8 or newer
- credentials for the selected cloud provider
- an AWS or Azure subscription/account with permission to create the resources

```bash
git clone https://github.com/xturnal2/bluealpha-tofu.git
cd bluealpha-tofu/templates/aws/vpc
cp example.tfvars terraform.tfvars
# Edit terraform.tfvars.
tofu init
tofu plan
tofu apply
```

OpenTofu automatically reads `terraform.tfvars`. Keep that file local because it
may contain environment-specific or sensitive values.

## Design contract

Templates in this repository follow these rules:

1. A template is directly runnable; consumers do not need to copy internal
   modules or install a wrapper.
2. Defaults avoid public ingress and optional managed services that create
   material recurring charges.
3. Every optional behavior is exposed as a documented variable.
4. Resource names include a user-provided project and environment.
5. Tags identify the project, environment, template, and OpenTofu ownership.
6. Outputs expose IDs needed by downstream stacks without returning secrets.

See [CONTRIBUTING.md](CONTRIBUTING.md) for the acceptance checklist for new
templates and [ROADMAP.md](ROADMAP.md) for the incremental delivery plan.

## Versioning and support

The repository uses semantic version tags. Pin a release when consuming a
template in automation, and review release notes before upgrading.

These templates are starting points, not a substitute for an architecture and
security review. Cloud costs, service availability, and compliance requirements
vary by account and region. Always inspect `tofu plan` before applying.

## License

Licensed under the [Apache License 2.0](LICENSE).
