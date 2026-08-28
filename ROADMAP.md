# Template roadmap

This roadmap keeps the repository useful at every step while giving each stack
a focused commit and review. It is directional: customer demand can move a stack
earlier, and implementation does not begin until its scope is selected.

## Delivery strategy

Repository foundation and each stack are separate changes. A stack lands only
when its code, README, example variables, and automated validation are complete.
Avoid placeholder directories or partially documented templates on `main`.

The normal commit sequence is:

1. `chore(repo): scaffold public OpenTofu template catalog`
2. `feat(<cloud>): add <stack> template`
3. `fix(<cloud>): ...` or `docs(<cloud>): ...` only when follow-up is genuinely
   independent of the stack's initial implementation

Closely related stacks may be delivered as a small group, but each remains a
separate commit so consumers can follow the history and releases can call out
exactly what changed.

## Proposed sequence

### Group 1: Network foundations

These provide the base IDs and subnet boundaries used by later workload stacks.

| Order | Stack | Initial scope | High-impact choices to expose |
|---:|---|---|---|
| 1 | [`aws/vpc`](templates/aws/vpc) — available | Multi-AZ VPC, public/private subnets, routing | zone count, CIDRs, NAT topology, flow logs |
| 2 | [`azure/vnet`](templates/azure/vnet) — available | VNet, map-driven subnets, NSGs | CIDRs, service endpoints, delegations, NSGs, NAT gateway |

Suggested commits:

- `feat(aws): add configurable VPC foundation`
- `feat(azure): add configurable virtual network foundation`

### Group 2: Static web delivery

These are low-friction examples customers can evaluate without deploying an
application runtime.

| Order | Stack | Initial scope | High-impact choices to expose |
|---:|---|---|---|
| 3 | [`aws/static-website`](templates/aws/static-website) — available | Private S3 origin and CloudFront | versioning, logs, SPA fallback, price class |
| 4 | [`azure/static-website`](templates/azure/static-website) — available | Storage static site and optional Front Door | replication, versioning, retention, CDN |

Suggested commits:

- `feat(aws): add secure static website template`
- `feat(azure): add static website template`

### Group 3: Container application runtimes

Networking inputs should accept outputs from Group 1 without coupling the
stacks through local state.

| Order | Stack | Initial scope | High-impact choices to expose |
|---:|---|---|---|
| 5 | [`aws/ecs-fargate-service`](templates/aws/ecs-fargate-service) — available | ECS service, ALB, autoscaling, logs | CPU/memory, desired count, public ingress, scaling |
| 6 | [`azure/container-apps`](templates/azure/container-apps) — available | Environment, app, ingress, scaling, logs | CPU/memory, min/max replicas, ingress, revisions |

### Group 4: Managed PostgreSQL

Database stacks should default to private connectivity, encryption, backups,
and deletion protection appropriate to the selected environment.

| Order | Stack | Initial scope | High-impact choices to expose |
|---:|---|---|---|
| 7 | [`aws/rds-postgresql`](templates/aws/rds-postgresql) — available | RDS PostgreSQL and subnet group | instance class, Multi-AZ, backup retention, protection |
| 8 | [`azure/postgresql-flexible`](templates/azure/postgresql-flexible) — available | Flexible Server and private DNS | SKU, zone redundancy, storage, backup retention |

### Group 5: Serverless HTTP APIs

| Order | Stack | Initial scope | High-impact choices to expose |
|---:|---|---|---|
| 9 | [`aws/lambda-api`](templates/aws/lambda-api) — available | Lambda, HTTP API, logs, least-privilege role | runtime, memory, timeout, CORS, log retention |
| 10 | [`azure/functions-http`](templates/azure/functions-http) — available | Function App, plan, storage, monitoring | runtime, plan tier, scaling, CORS, retention |

### Group 6: Messaging and NoSQL data

These stacks provide durable asynchronous messaging and serverless persistence
for the application runtimes without coupling consumers to local state.

| Order | Stack | Initial scope | High-impact choices to expose |
|---:|---|---|---|
| 11 | [`aws/sqs-queue`](templates/aws/sqs-queue) — available | Encrypted queue and restricted dead-letter queue | FIFO, retention, visibility timeout, KMS |
| 12 | [`azure/service-bus-queue`](templates/azure/service-bus-queue) — available | Service Bus namespace, queue, and dead-letter behavior | tier, capacity, sessions, TTL |
| 13 | [`aws/dynamodb-table`](templates/aws/dynamodb-table) — available | DynamoDB table, recovery, TTL, and streams | billing mode, indexes, deletion protection, backups |
| 16 | [`aws/sns-topic`](templates/aws/sns-topic) — available | Encrypted fan-out topic with filtering and delivery controls | FIFO, subscriptions, KMS, archives |
| 19 | [`azure/event-grid-topic`](templates/azure/event-grid-topic) — available | Entra-authenticated custom event topic with common destinations | schema, local auth, IP rules, subscriptions |
| 22 | [`aws/eventbridge-bus`](templates/aws/eventbridge-bus) — available | Custom event bus with scoped publishers and replay archive | KMS, archive retention, cross-account publishing |
| 23 | [`azure/event-hubs`](templates/azure/event-hubs) — available | Entra-authenticated partitioned event stream with consumer groups | tier, capacity, partitions, retention, network rules |

### Group 7: Artifact registries and platform security

These stacks provide image distribution and secret-management foundations for
the existing application runtimes.

| Order | Stack | Initial scope | High-impact choices to expose |
|---:|---|---|---|
| 14 | [`aws/ecr-repository`](templates/aws/ecr-repository) — available | Private container image repository with scanning and retention | tag mutability, lifecycle limits, KMS, cross-account access |
| 15 | [`azure/container-registry`](templates/azure/container-registry) — available | Entra-authenticated container registry with optional Premium controls | SKU, public access, network rules, geo-replication |
| 17 | [`azure/key-vault`](templates/azure/key-vault) — available | RBAC-authorized vault boundary with recovery and network controls | tier, purge protection, public access, role assignments |
| 25 | [`azure/managed-identity`](templates/azure/managed-identity) — available | User-assigned workload identity with OIDC federation | federation subjects, RBAC scopes, regional isolation |
| 18 | [`aws/secrets-manager-secret`](templates/aws/secrets-manager-secret) — available | Metadata-only secret boundary with recovery and regional replicas | KMS, recovery, replicas, access policy |
| 24 | [`aws/kms-key`](templates/aws/kms-key) — available | Rotating symmetric encryption key and alias | rotation, deletion window, multi-Region, key users |

### Group 8: General-purpose object storage

These stacks provide private application storage without the website-delivery
behavior of the static-site templates.

| Order | Stack | Initial scope | High-impact choices to expose |
|---:|---|---|---|
| 20 | [`aws/s3-bucket`](templates/aws/s3-bucket) — available | Private encrypted bucket with version recovery and lifecycle hygiene | versioning, KMS, expiration, force destroy |
| 21 | [`azure/storage-account`](templates/azure/storage-account) — available | Entra-first private object storage with versioning and recovery | redundancy, shared keys, public access, retention |

### Group 9: Observability foundations

These stacks give workloads an independently managed destination for logs and
make retention, encryption, and deletion behavior explicit.

| Order | Stack | Initial scope | High-impact choices to expose |
|---:|---|---|---|
| 26 | [`aws/cloudwatch-log-group`](templates/aws/cloudwatch-log-group) — available | Application log storage with finite retention and guarded deletion | retention, storage class, KMS, deletion protection |
| 27 | [`azure/log-analytics-workspace`](templates/azure/log-analytics-workspace) — available | Shared telemetry workspace with Entra authorization and spend controls | retention, daily quota, public endpoints, RBAC |

### Group 10: DNS foundations

These stacks establish independently managed public DNS delegation and the
record interfaces used by application delivery stacks.

| Order | Stack | Initial scope | High-impact choices to expose |
|---:|---|---|---|
| 28 | [`aws/route53-zone`](templates/aws/route53-zone) — available | Public or VPC-private hosted zone with common records | zone visibility, VPC associations, aliases, force destroy |
| 29 | [`azure/dns-zone`](templates/azure/dns-zone) — available | Public authoritative zone with common records and scoped automation | records, Azure aliases, SOA timings, RBAC |

### Group 11: Identity and cost governance

These stacks establish reusable authorization boundaries and proactive cloud
spend notifications independently from individual workloads.

| Order | Stack | Initial scope | High-impact choices to expose |
|---:|---|---|---|
| 30 | [`aws/iam-role`](templates/aws/iam-role) — available | Workload or cross-account role with explicit trust and permissions | trust principals, external ID, boundary, policy attachments |
| 31 | [`azure/custom-role`](templates/azure/custom-role) — available | Least-privilege custom RBAC definition and optional assignments | actions, data actions, assignable scopes, principals |
| 32 | [`aws/account-budget`](templates/aws/account-budget) — available | Account or filtered cost budget with proactive notifications | amount, period, filters, charge types, subscribers |
| 33 | [`azure/subscription-budget`](templates/azure/subscription-budget) — available | Subscription cost budget with filters and routed notifications | amount, period, filters, emails, action groups |

### Group 12: Monitoring and alerting

These stacks separate shared notification routing, metric detection, and
operational visualization from application resource lifecycles.

| Order | Stack | Initial scope | High-impact choices to expose |
|---:|---|---|---|
| 34 | [`aws/cloudwatch-metric-alarm`](templates/aws/cloudwatch-metric-alarm) — available | Static metric threshold with M-of-N evaluation and actions | threshold, periods, missing data, destinations |

## Connected architecture examples

Connected examples are larger root configurations that compose published
templates and document the seams between networking, identity, runtime, and
data services.

| Order | Example | Initial scope | High-impact choices to expose |
|---:|---|---|---|
| 1 | [`aws/connected-app-platform`](examples/aws/connected-app-platform) — available | VPC, ECS, PostgreSQL, SQS, and DynamoDB | NAT topology, ingress, app scaling, database resilience/protection |

## Stack definition of done

Every stack or connected-example change must include:

- bounded OpenTofu and provider version constraints;
- safe defaults, standard tags, variable validation, and useful outputs;
- `README.md` covering architecture, prerequisites, authentication, costs,
  security, operations, inputs, outputs, and destroy behavior;
- `example.tfvars` with no secrets or customer-specific identifiers;
- successful `tofu fmt -check`, `tofu init -backend=false`, and
  `tofu validate`;
- a review of flags that create public access, reduce resilience, weaken
  deletion protection, or add material recurring charges;
- an update to the root catalog and dependency-update configuration.

When cloud credentials and a disposable subscription/account are available, a
redacted plan or apply/destroy smoke test should be attached to the pull request.

## Release approach

- Use pull requests even for single-stack commits.
- Tag the first stable stack catalog as `v0.1.0`.
- Continue `0.x` releases while interfaces may change based on customer use.
- Record breaking input/output changes in release notes and provide a migration
  example.
- Graduate to `v1.0.0` after at least one AWS and one Azure stack have been
  exercised in customer-like environments and the repository conventions have
  stabilized.
