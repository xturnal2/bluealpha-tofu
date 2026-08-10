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
| AWS | [ECS Fargate service](templates/aws/ecs-fargate-service) | Container service behind an Application Load Balancer | `desired_count`, `use_fargate_spot`, `enable_autoscaling` |
| AWS | [RDS PostgreSQL](templates/aws/rds-postgresql) | Private encrypted PostgreSQL with backups and managed credentials | `multi_az`, `deletion_protection`, `backup_retention_days` |
| AWS | [Lambda HTTP API](templates/aws/lambda-api) | Packaged Lambda behind an HTTP API with logs and throttling | `memory_size`, `reserved_concurrent_executions`, `throttle_rate_limit` |
| AWS | [SQS queue](templates/aws/sqs-queue) | Encrypted queue with optional FIFO behavior and a restricted DLQ | `create_dead_letter_queue`, `fifo_queue`, `kms_master_key_id` |
| Azure | [Virtual network](templates/azure/vnet) | VNet with configurable subnets, NSGs, delegations, and optional NAT Gateway | `enable_nat_gateway`, `create_network_security_groups` |
| Azure | [Static website](templates/azure/static-website) | Storage static website with optional Front Door delivery | `enable_cdn`, `enable_versioning`, `account_replication_type` |
| Azure | [Container Apps](templates/azure/container-apps) | Consumption-scaled container app with ingress and logs | `min_replicas`, `max_replicas`, `external_ingress_enabled` |
| Azure | [PostgreSQL Flexible Server](templates/azure/postgresql-flexible) | Private managed PostgreSQL with DNS and backups | `sku_name`, `high_availability_mode`, `geo_redundant_backup_enabled` |
| Azure | [Functions HTTP](templates/azure/functions-http) | Linux Function App with storage, monitoring, and HTTP controls | `plan_sku_name`, `maximum_instance_count`, `ip_restrictions` |
| Azure | [Service Bus queue](templates/azure/service-bus-queue) | Entra-authenticated namespace and queue with DLQ behavior | `sku`, `premium_messaging_units`, `requires_session` |

See the [roadmap](ROADMAP.md) for the planned AWS and Azure stacks and their
proposed delivery order.

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
