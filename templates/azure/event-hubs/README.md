# Azure Event Hubs

Creates an Azure Event Hubs namespace, one event stream, consumer groups, and
scoped RBAC with Microsoft Entra authentication and TLS 1.2 by default. Network
allowlists, auto-inflate, partitions, and retention are explicit choices.

## Architecture

- optional resource group and one Basic, Standard, or Premium namespace;
- system-assigned namespace identity and local SAS authentication disabled;
- one Event Hub with configurable partitions and retention;
- map-driven consumer groups and Event Hub-scoped RBAC;
- optional IPv4 and virtual-network service-endpoint restrictions.

## Usage

```bash
az login
az account set --subscription 00000000-0000-0000-0000-000000000000
cp example.tfvars terraform.tfvars
tofu init
tofu plan
tofu apply
az eventhubs eventhub show \
  --resource-group "$(tofu output -raw resource_group_name)" \
  --namespace-name "$(tofu output -raw namespace_name)" \
  --name "$(tofu output -raw eventhub_name)"
```

## Important flags

| Flag | Default | Impact |
|---|---:|---|
| `sku` | `Standard` | Controls features and fixed capacity cost; Premium changes capacity semantics |
| `capacity` | `1` | Sets purchased throughput/processing units |
| `auto_inflate_enabled` | `false` | Standard-only automatic throughput growth up to a configured cost ceiling |
| `partition_count` | `4` | Sets maximum consumer parallelism; reducing partitions is not supported |
| `message_retention_days` | `1` | Extends the replay window and storage usage |
| `local_authentication_enabled` | `false` | Enabling permits SAS keys/connection strings; prefer Entra identities |
| `public_network_access_enabled` | `true` | Exposes authenticated endpoints; disable after private endpoint/DNS setup |
| `allowed_*` | `[]` | Non-empty lists make the namespace network default deny |
| `consumer_groups` | `application` | Isolates offsets for independent consuming applications |
| `role_assignments` | `{}` | Grants sender/receiver roles to explicit managed identities |

## Capacity, partitions, and consumers

Choose partitions from expected peak parallelism and key distribution before
production. Ordering exists only within a partition, and hot partition keys can
limit throughput. Each independent application gets its own consumer group;
instances within a group coordinate partition ownership and checkpoints.

Standard throughput units cover ingress and egress quotas. Auto-inflate helps
with bursts but only scales upward and can increase cost; alarms and a deliberate
maximum are still required. Premium processing units and Basic feature limits
should be validated against current regional service capabilities.

Retention lets consumers replay after outages but is not a permanent archive.
Use Event Hubs Capture or a consumer-owned data lake when durable analytical
retention is required.

## Identity and networking

SAS authentication is disabled by default. Grant producers `Azure Event Hubs
Data Sender` and consumers `Azure Event Hubs Data Receiver` at the Event Hub
scope through `role_assignments`. Workloads should use managed identity or
workload federation. The namespace identity does not grant client access.

Public endpoints remain authenticated. IP/subnet rules change the default to
deny; subnet IDs need the `Microsoft.EventHub` service endpoint. For private-only
traffic, create private endpoints and private DNS separately, verify producer
and consumer resolution, then disable public access.

## Inputs and outputs

Required inputs are `subscription_id` and `project_name`. Variables cover
resource-group ownership, namespace/entity naming, tier/capacity, partitions,
retention, authentication, networking, consumer groups, RBAC, environment, and
tags. Outputs expose resource IDs/names, consumer groups, identity, and group.

## Cost, monitoring, and destroy behavior

Tier, capacity, retention, Capture, private endpoints, ingress/egress, and
cross-region traffic drive cost. Monitor incoming/outgoing requests and bytes,
throttling, server errors, consumer lag, checkpoint age, active connections,
partition skew, authorization failures, and auto-inflate capacity.

Destroying the Event Hub permanently removes retained events and consumer
groups. Stop producers, drain consumers, export required event history, and
remove dependencies before destroying the namespace.
