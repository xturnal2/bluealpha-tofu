# Azure Event Grid Topic

Creates an Azure Event Grid custom topic with Microsoft Entra publishing by
default, optional public IP restrictions, a managed identity, scoped publisher
roles, and map-driven event subscriptions for common Azure destinations.

## Architecture

- an optional resource group and one Event Grid custom topic;
- system-assigned managed identity on the topic;
- topic-scoped `EventGrid Data Sender` assignments for publisher identities;
- local access keys disabled by default;
- optional Azure Function, Event Hubs, Service Bus, Storage Queue, and webhook
  subscriptions with subject filters and retry policies.

## Usage

```bash
az login
az account set --subscription 00000000-0000-0000-0000-000000000000
cp example.tfvars terraform.tfvars
tofu init
tofu plan
tofu apply
az eventgrid topic show \
  --resource-group "$(tofu output -raw resource_group_name)" \
  --name "$(tofu output -raw topic_name)"
```

The provisioning identity needs role-assignment write permission when publisher
assignments are configured. Custom topics are not available in every region;
confirm current regional availability before selecting `location`.

## Important flags

| Flag | Default | Impact |
|---|---:|---|
| `input_schema` | `EventGridSchema` | Defines the publisher payload contract and is replacement-sensitive |
| `local_auth_enabled` | `false` | Enabling creates shared access-key publishing paths; prefer Entra identities |
| `public_network_access_enabled` | `true` | Exposes an authenticated endpoint; disable after separate private endpoint/DNS setup |
| `allowed_ip_cidrs` | `[]` | Restricts public publishing to explicit IPv4 networks |
| `publisher_role_assignments` | `{}` | Grants topic-scoped publishing to named Entra principals |
| `event_subscriptions` | `{}` | Adds delivery endpoints, filters, retry traffic, and downstream service cost |

## Authentication and networking

Local authentication is disabled by default so publishers use Entra tokens and
the `EventGrid Data Sender` role. Managed identity or workload identity avoids
long-lived topic keys. If legacy publishers require keys, enabling local auth is
an explicit downgrade; store keys in a vault and rotate them.

Public network access still requires authentication. `allowed_ip_cidrs` narrows
which public source networks can publish. For private-only publishing, create a
private endpoint and private DNS in a connected networking stack, validate name
resolution and token-based publishing, then disable public network access.

The topic managed identity can participate in supported delivery and
dead-letter scenarios but is not automatically authorized at downstream
resources. Grant only the destination roles required by the selected endpoint.

## Subscription endpoints

Subscriptions use stable map keys, which become their names. Set `endpoint_type`
to `azure_function`, `eventhub`, `service_bus_queue`, `service_bus_topic`,
`storage_queue`, or `webhook`. `endpoint` is the destination resource ID except
for a webhook URL; Storage Queue uses the storage-account ID plus
`storage_queue_name`.

Destination ownership remains outside this template. Service Bus, Event Hubs,
Storage, and Function endpoints require compatible authorization and network
access. Webhooks must complete Event Grid endpoint validation and should use
HTTPS, application authentication, replay protection, and idempotent processing.

Subject filters and included event types reduce unnecessary delivery but are
not authorization boundaries. Consumers must validate schema, tenant/topic,
event type, subject, and data. Retry policy allows 1-30 delivery attempts and a
1-1440 minute event TTL. Production subscriptions should use an explicitly
designed dead-letter destination; advanced filtering and dead-letter identities
can be added in a workload-specific composition when needed.

## Schema choices

`EventGridSchema` is the interoperable default for Azure-native consumers.
`CloudEventSchemaV1_0` is useful for CloudEvents-based applications.
`CustomEventSchema` requires mapping fields that are workload-specific and is
best extended in a specialized copy of this root stack. Schema changes can
replace the topic, so version and test publisher/consumer contracts first.

## Inputs and outputs

Required inputs are `subscription_id` and `project_name`. Variables cover
resource-group ownership, naming, location, schema, authentication, network
access, publisher RBAC, subscriptions, environment, and tags.

Outputs expose the topic ID/name/endpoint, managed identity principal ID,
subscription IDs, and resource-group name. Access keys are never output.

## Cost, monitoring, and destroy behavior

Published and delivered operations, retries, dead-letter storage, destination
services, private endpoints, and monitoring drive cost. Monitor publish and
delivery failures, dropped/dead-lettered events, retry counts, authentication
denials, latency, destination health, and role/network changes.

`tofu destroy` removes the managed subscriptions and topic but not downstream
destinations. Stop publishers, drain or retain required events, and confirm
consumer recovery behavior before deletion. Event Grid is transport, not a
durable event archive unless an appropriate destination provides retention.
