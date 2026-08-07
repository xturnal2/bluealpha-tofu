# Azure PostgreSQL Flexible Server

Creates a private Azure Database for PostgreSQL Flexible Server with encrypted
storage, automated backups, private DNS, and an optional application database.

## Architecture

- one new or existing resource group;
- PostgreSQL Flexible Server attached to a delegated subnet with public network
  access disabled;
- a new private DNS zone and VNet link, or an existing private DNS zone;
- a generated administrator password by default;
- optional high availability, geo-redundant backups, maintenance window, and
  server configurations.

## Prerequisites and usage

Create a subnet delegated to
`Microsoft.DBforPostgreSQL/flexibleServers`. The Azure VNet template can create
the subnet and export its ID.

```bash
az login
export ARM_SUBSCRIPTION_ID="00000000-0000-0000-0000-000000000000"
cp example.tfvars terraform.tfvars
tofu init
tofu plan
tofu apply
```

The deploying identity needs permission to create the server and DNS resources,
plus permission to join the delegated subnet.

## Important flags

| Flag | Default | Impact |
|---|---:|---|
| `sku_name` | `B_Standard_B1ms` | Selects the compute tier and is a primary cost driver |
| `storage_mb` | `32768` | Provisions database storage; storage can grow but not shrink |
| `auto_grow_enabled` | `true` | Reduces outage risk as allocated storage fills |
| `backup_retention_days` | `7` | Controls point-in-time restore history and backup cost |
| `geo_redundant_backup_enabled` | `false` | Adds regional backup resilience and recurring cost |
| `high_availability_mode` | `Disabled` | `SameZone` or `ZoneRedundant` adds a standby and compute cost |
| `create_private_dns_zone` | `true` | Creates and links DNS; set false to use a centrally managed zone |
| `server_configurations` | `{}` | Applies explicit PostgreSQL engine configuration values |

SKU, PostgreSQL version, zone redundancy, and geo-redundant backup availability
vary by region. Confirm availability before applying.

## Networking and DNS

The server has no public endpoint. `delegated_subnet_id` is always required. By
default, the stack creates a private DNS zone and requires `virtual_network_id`
to link it. To reuse central DNS, set `create_private_dns_zone = false` and pass
`private_dns_zone_id`; the existing zone must already be linked to every client
VNet that needs name resolution.

Network access also depends on subnet routing, NSGs, peering, and DNS forwarding
outside this stack. Applications connect to output `fqdn` on port 5432.

## Credentials and state

When `administrator_password` is null, the stack generates a 24-character
password and returns it through the sensitive
`generated_administrator_password` output. Retrieve it with:

```bash
tofu output -raw generated_administrator_password
```

Supplied and generated passwords are stored in OpenTofu state. Encrypt and
tightly restrict state. For production, transfer the credential to Key Vault or
adopt Microsoft Entra authentication, rotate it, and avoid distributing the
administrator account to applications.

## Inputs and outputs

Required inputs are `project_name` and `delegated_subnet_id`, plus
`virtual_network_id` for a newly created DNS zone. Variables cover resource
placement, DNS reuse, server naming, engine version, SKU, storage, backups,
availability, database creation, configuration, maintenance, and tags. See
`variables.tf` for exact types and validation.

Outputs include the server ID, name, private FQDN, administrator login, optional
generated password, database name, resource group, and private DNS zone ID.

## Cost, operations, and destroy behavior

Compute, allocated storage, backup retention, geo-redundant backup, and high
availability drive cost. Burstable compute is economical for development but is
not appropriate for every sustained workload. Monitor CPU credits, connections,
storage, replication, and failed authentication.

`tofu destroy` deletes the server and its databases, backups managed with the
server, and a DNS zone created by this stack. It does not delete the external
VNet, delegated subnet, or a reused DNS zone. Export or restore-test critical
data before destructive changes; OpenTofu does not add a destroy guard.
