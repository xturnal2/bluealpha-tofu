# Azure Log Analytics workspace

Creates a Log Analytics workspace as a shared observability boundary for Azure
resources and applications. The default configuration uses Entra ID rather than
shared keys, keeps 30 days of interactive data, and caps ingestion at 1 GB per
day to limit accidental spend.

## Architecture

- An optional dedicated resource group.
- One Log Analytics workspace with usage-based billing by default.
- Explicit retention and daily ingestion quota.
- Separate controls for public ingestion and query endpoints.
- Optional workspace-scoped Azure RBAC assignments.

Diagnostic settings, data collection endpoints and rules, private links,
alerts, and individual table retention belong with their producing workloads or
an organization-wide monitoring design. They are intentionally not hidden in
this storage-boundary template.

## Prerequisites and authentication

- OpenTofu 1.8 or newer.
- An Azure subscription and a principal allowed to create the resource group,
  workspace, and requested role assignments.
- Azure CLI, workload identity, managed identity, or service-principal
  authentication configured outside variable files.

## Usage

```bash
cp example.tfvars terraform.tfvars
tofu init
tofu plan
tofu apply
```

Pass `workspace_id` to Container Apps, Functions, diagnostic settings, or other
stacks that send telemetry. The `workspace_customer_id` output is not a secret;
shared keys are deliberately not exposed.

## Important inputs

| Input | Default | Purpose |
|---|---:|---|
| `create_resource_group` | `true` | Creates or reuses the monitoring resource group. |
| `retention_in_days` | `30` | Sets interactive retention from 30 through 730 days. |
| `daily_quota_gb` | `1` | Caps ingestion; `-1` explicitly removes the cap. |
| `sku` | `PerGB2018` | Selects usage billing or a capacity commitment. |
| `local_authentication_enabled` | `false` | Enables legacy shared-key authentication. |
| `internet_ingestion_enabled` | `true` | Allows authenticated ingestion through the public endpoint. |
| `internet_query_enabled` | `true` | Allows authenticated queries through the public endpoint. |
| `role_assignments` | `{}` | Grants least-privilege workspace roles. |

## Cost considerations

Ingestion and retention beyond included allowances are the main costs. Queries,
exports, data collection, alert rules, and linked services can add charges.
Keep a finite daily quota in evaluation environments and alert as the cap is
approached. `CapacityReservation` creates a material daily commitment and
requires `reservation_capacity_in_gb_per_day`; select it only after reviewing
stable ingestion volume.

## Security and operations

- Shared-key authentication is disabled by default. Use managed identities and
  narrowly scoped Azure RBAC roles.
- Public endpoints still require authentication. Disable them only after Azure
  Monitor Private Link Scope and private DNS are configured, or ingestion and
  queries can stop.
- A quota protects cost but drops new data after the cap is reached. Monitor
  quota status and choose a value that preserves operational visibility.
- Keep immediate 30-day purge disabled when recovery or longer soft-delete
  behavior is required.
- Apply different retention or classification policies at the table level when
  a single workspace stores data with different requirements.

## Outputs

The stack returns the workspace resource ID, name, non-secret customer ID, and
resource group name. It never returns workspace shared keys.

## Destroy behavior

Destroy removes role assignments, the workspace, and the resource group when
this stack created it. Azure workspace recovery and name reservation behavior
can affect immediate recreation. Export required data and detach diagnostic
settings before destroying a production workspace.
