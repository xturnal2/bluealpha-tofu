# Azure Storage Account

Creates a private-data-oriented Azure StorageV2 account with HTTPS-only traffic,
TLS 1.2, infrastructure encryption, Microsoft Entra authentication preference,
blob versioning, soft-delete recovery, optional private containers, network
rules, and scoped RBAC.

## Architecture

- an optional resource group and one Standard StorageV2 account;
- shared access keys and local users disabled by default;
- nested items cannot be made public and all created containers are private;
- system-assigned managed identity and optional storage-scoped RBAC assignments;
- blob versioning plus 30-day blob/container soft delete;
- optional IPv4 and virtual-network service-endpoint rules;
- optional private blob containers managed by stable map keys.

This general-purpose stack does not enable static website hosting. Use the
separate Azure static website template for public web delivery and Front Door.

## Usage

```bash
az login
az account set --subscription 00000000-0000-0000-0000-000000000000
cp example.tfvars terraform.tfvars
tofu init
tofu plan
tofu apply
az storage account show \
  --resource-group "$(tofu output -raw resource_group_name)" \
  --name "$(tofu output -raw storage_account_name)"
```

Creating `containers` requires blob data-plane permission for the provisioning
identity, such as `Storage Blob Data Contributor`, in addition to control-plane
permission. Role assignments require authorization write permission.

## Important flags

| Flag | Default | Impact |
|---|---:|---|
| `account_replication_type` | `LRS` | Lowest-cost local copies; ZRS and geo-redundant families improve resilience and cost more |
| `access_tier` | `Hot` | Sets the default storage/request cost tradeoff for new blobs |
| `shared_access_key_enabled` | `false` | Enabling restores account keys and Shared Key/SAS authorization paths |
| `public_network_access_enabled` | `true` | Exposes authenticated endpoints; disable after private endpoints/DNS are ready |
| `allowed_ip_rules` / `allowed_subnet_ids` | `[]` | Non-empty values change network default to deny and admit only configured networks/bypasses |
| `versioning_enabled` | `true` | Retains previous blob versions and increases storage usage |
| `*_delete_retention_days` | `30` | Keeps deleted blobs/containers recoverable for 1-365 days |
| `change_feed_enabled` | `false` | Records ordered blob changes for downstream processing and adds storage |
| `hierarchical_namespace_enabled` | `false` | Enables Data Lake Gen2 semantics and affects supported features/replacement |
| `containers` | `{}` | Creates private containers; their data is deleted with the account |
| `role_assignments` | `{}` | Grants named identities scoped data-plane roles without creating credentials |

## Identity and authorization

The account prefers OAuth and disables shared access keys and local users.
Applications should use managed identity or workload identity with a data-plane
role such as `Storage Blob Data Reader` or `Storage Blob Data Contributor`.
Control-plane Contributor access does not automatically grant blob reads.

The storage account managed identity is for storage integrations and encryption
scenarios; it does not grant client access. No account keys, SAS tokens, or
connection strings are output. If legacy software requires Shared Key, enabling
it is an explicit compatibility tradeoff; rotate keys and avoid distributing
connection strings broadly.

## Network model

Public network access still requires Entra authorization. With empty allowlists,
authenticated clients can reach public endpoints. Adding IP or subnet entries
changes the network default to deny while retaining configured bypass services.
Subnet rules require the `Microsoft.Storage` service endpoint.

For private-only storage, create private endpoints and the relevant
`privatelink.*.core.windows.net` DNS zones in a connected networking stack,
verify every service endpoint your workload uses, then disable public access.
IP/subnet rules are intentionally rejected when public networking is disabled
because private endpoint policy belongs to the endpoint and DNS design.

## Recovery, replication, and Data Lake

Versioning and soft delete protect common overwrite/delete mistakes but are not
immutable backup. Test restores and manage old versions with an explicit
lifecycle policy appropriate to retention rules. Change feed can support audit
and processing workflows but is not a substitute for diagnostic logs.

LRS is cost-conscious and keeps copies within one datacenter boundary. Choose
ZRS for zone resilience where available or GRS/GZRS families for regional
copies after reviewing failover, RPO/RTO, read-access variants, residency, and
cost. Replication does not protect against every logical deletion or account
deletion scenario.

Hierarchical namespace enables Data Lake Gen2 directory/ACL semantics. Treat it
as an architectural choice: confirm protocol, feature, redundancy, and migration
compatibility before enabling it.

## Inputs and outputs

Required inputs are `subscription_id` and `project_name`. Variables cover
resource-group ownership, naming, redundancy, access tier, identity/network
controls, recovery, change feed, Data Lake, containers, RBAC, environment, and
tags. Outputs expose the account ID/name, blob endpoint, managed identity,
container IDs, and resource-group name.

## Cost, monitoring, and destroy behavior

Capacity, transactions, redundancy, access tier, retrieval, versions, soft
delete, change feed, private endpoints, replication, and data transfer drive
cost. Monitor capacity/transactions, availability, latency, throttling,
authentication failures, network denials, replication status, and old versions.

Destroying the storage account permanently removes all services, containers,
blobs, versions, queues, tables, and file shares in it. Soft delete is not an
account-deletion guarantee. Inventory every service, copy required data to an
independent account, and verify recovery before destroy or replacement.
