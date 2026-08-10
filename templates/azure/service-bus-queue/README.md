# Azure Service Bus Queue

Creates an Azure Service Bus namespace and durable queue with Microsoft Entra
authentication, TLS 1.2, and dead-lettering on expired messages by default. The
stack supports development-friendly Standard and dedicated Premium deployments
without returning SAS keys or connection strings.

## Architecture

- one new or existing resource group;
- globally named Basic, Standard, or Premium Service Bus namespace with a
  system-assigned managed identity;
- one queue with Peek Lock, retry/dead-letter, TTL, duplicate detection,
  sessions, partitioning, and forwarding controls;
- optional queue-scoped Sender, Receiver, and Owner role assignments;
- optional Premium IP and virtual-network rules.

## Prerequisites and usage

```bash
az login
export ARM_SUBSCRIPTION_ID="00000000-0000-0000-0000-000000000000"
cp example.tfvars terraform.tfvars
tofu init
tofu plan
tofu apply
```

With `local_auth_enabled = false`, applications must use Microsoft Entra ID.
Pass each producer, consumer, or operator object ID through
`data_plane_role_assignments`, or manage equivalent RBAC separately. Azure role
assignments can take several minutes to propagate after apply.

## Important flags

| Flag | Default | Impact |
|---|---:|---|
| `sku` | `Standard` | Standard suits low-throughput/dev use; Premium adds dedicated capacity and networking controls |
| `premium_messaging_units` | `1` | Sets Premium compute capacity and fixed recurring cost |
| `premium_messaging_partitions` | `1` | Spreads Premium capacity across brokers and is fixed after creation |
| `local_auth_enabled` | `false` | Disables static SAS credentials and requires Entra data roles |
| `public_network_access_enabled` | `true` | Disabling requires separately managed private endpoints and DNS |
| `allowed_ip_cidrs` / `allowed_subnet_ids` | `[]` | On Premium, populating rules changes unmatched public traffic to Deny |
| `default_message_ttl` | `P14D` | Limits how long unconsumed messages occupy the queue |
| `max_delivery_count` | `10` | Controls retries before the built-in dead-letter subqueue |
| `requires_duplicate_detection` | `false` | Deduplicates sends by MessageId and is fixed after creation |
| `requires_session` | `false` | Enables ordered, stateful processing and is fixed after creation |
| `partitioning_enabled` | `false` | Enables Standard entity partitioning; Premium partitions at namespace level |

Service Bus tier guidance and current performance considerations are documented
in [Microsoft's performance best practices](https://learn.microsoft.com/azure/service-bus-messaging/service-bus-performance-improvements).

## Authentication and authorization

Local/SAS authentication is disabled by default to avoid distributing static
connection strings. Use current Azure SDKs with `DefaultAzureCredential` and a
managed identity, workload identity, or service principal. Queue-scoped role
assignments keep producers and consumers separate:

- `Azure Service Bus Data Sender` for producers;
- `Azure Service Bus Data Receiver` for consumers and DLQ readers;
- `Azure Service Bus Data Owner` only for applications that genuinely need both.

Azure control-plane Contributor access does not automatically grant data-plane
send/receive access. Avoid enabling local auth merely to work around an RBAC
propagation delay.

## Delivery, sessions, and duplicate detection

Peek Lock provides at-least-once processing: a consumer settles a successful
message, while an abandoned or expired lock permits redelivery. Consumers must
be idempotent. Set `lock_duration` longer than normal processing or renew the
lock while handling a message.

After `max_delivery_count`, Service Bus moves the message to the queue's built-in
`$DeadLetterQueue`. With `dead_lettering_on_message_expiration = true`, expired
messages move there as well. Monitor, inspect, and explicitly resubmit DLQ
messages after repairing the cause.

Sessions provide FIFO ordering within a `SessionId`, not across the entire
queue. Duplicate detection discards repeated `MessageId` values inside
`duplicate_detection_history_time_window`; it protects send retries but does
not replace idempotent receive processing. Microsoft documents the current
[duplicate-detection behavior](https://learn.microsoft.com/azure/service-bus-messaging/enable-duplicate-detection).

## Networking

The public namespace endpoint remains enabled by default but still requires
Entra authorization. Premium users can set IP/subnet allow lists. When either
list is populated, unmatched traffic is denied. Allowed subnets need the
Microsoft.ServiceBus service endpoint; the template refuses to silently ignore
a missing endpoint.

Setting `public_network_access_enabled = false` does not create connectivity.
Provision private endpoints and `privatelink.servicebus.windows.net` DNS outside
this stack first. Network restrictions can also affect Azure services; enable
`trusted_services_allowed` only after reviewing the bypass implications.

## Tier and capacity choices

Standard is the economical default for development and lower-throughput systems
that tolerate shared-service throttling. Premium uses dedicated messaging units
for more predictable performance and supports private/network isolation.
Premium messaging units must divide evenly across the selected partition count.
Both tier changes and immutable partition choices deserve migration testing.

Basic lacks advanced features; the template rejects sessions, duplicate
detection, and forwarding on Basic. Queue and message-size availability also
depends on tier. Confirm regional support and current quotas before applying.

## Inputs and outputs

Only `project_name` is required. Variables cover resource placement, namespace
and queue naming, tier/capacity, auth, networking, queue size, TTL, locks,
delivery attempts, sessions, duplicate detection, partitioning, forwarding,
RBAC, and tags. See `variables.tf` for exact types and validation.

Outputs include namespace and queue IDs/names, endpoint, namespace identity, and
the built-in dead-letter entity path. No SAS key or connection string is exposed.

## Cost, monitoring, and destroy behavior

Namespace tier/capacity, brokered operations, connections, data transfer, and
Premium messaging units drive cost. Monitor active/dead-lettered messages,
incoming/outgoing requests, server errors, throttled requests, size, oldest
message age, and Premium CPU/memory where applicable.

`tofu destroy` permanently removes the namespace, queue, DLQ contents, and role
assignments. OpenTofu does not drain or archive messages. Stop senders, process
or export required messages, and verify recovery procedures first.
