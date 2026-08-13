# Azure Container Registry

Creates an Azure Container Registry with local admin and anonymous pull access
disabled, a system-assigned managed identity, and Entra ID role assignments.
Standard is the cost-conscious default; Premium unlocks network allowlists,
untagged-manifest retention, zone redundancy, and geo-replication.

## Architecture

- an optional resource group and one Azure Container Registry;
- system-assigned managed identity on the registry;
- optional `AcrPull`, `AcrPush`, or other scoped RBAC assignments;
- authenticated public endpoint by default, with Premium IPv4 allowlists;
- optional Premium retention, zone redundancy, and regional replicas.

This template does not create private endpoints or private DNS. Set
`public_network_access_enabled = false` only when those are supplied by a
network stack or another root configuration.

## Prerequisites and usage

```bash
az login
az account set --subscription 00000000-0000-0000-0000-000000000000
cp example.tfvars terraform.tfvars
tofu init
tofu plan
tofu apply
az acr login --name "$(tofu output -raw registry_name)"
```

The provisioning identity needs resource creation permissions and, when
`role_assignments` is non-empty, `Microsoft.Authorization/roleAssignments/write`
at the registry scope or above.

## Important flags

| Flag | Default | Impact |
|---|---:|---|
| `sku` | `Standard` | Premium adds network rules, replicas, retention, redundancy, and substantially higher fixed cost |
| `admin_enabled` | `false` | Enabling creates shared username/password credentials; prefer Entra ID |
| `anonymous_pull_enabled` | `false` | Enabling permits unauthenticated image downloads on supported tiers |
| `public_network_access_enabled` | `true` | Exposes an authenticated endpoint; disabling requires separately managed private connectivity |
| `allowed_ip_cidrs` | `[]` | Premium-only allowlist that changes the public network default to deny |
| `trusted_services_allowed` | `true` | Lets supported Azure services bypass network restrictions while still authenticating |
| `retention_policy_in_days` | `7` | Premium-only automatic cleanup of untagged manifests; `0` disables retention |
| `zone_redundancy_enabled` | `false` | Premium resilience option available only in supported regions |
| `georeplications` | `{}` | Premium regional replicas add availability, storage, and data-transfer cost |
| `export_policy_enabled` | `true` | Premium control for image export; disabling also requires public access disabled |

## Authentication and authorization

The registry admin account and anonymous pulls are disabled by default. Use
managed identities or workload identity federation for build and runtime
access. Populate `role_assignments` with stable labels and principal object IDs;
`AcrPull` suits runtimes and `AcrPush` suits trusted build pipelines. Avoid
broad subscription-level assignments when registry scope is sufficient.

The registry system identity is for registry integrations and encryption
scenarios; it does not grant clients permission to pull images. This template
does not output admin credentials or place credentials in configuration.

## Network model

Public network access does not make images anonymous: Entra authentication and
RBAC still apply. Standard is appropriate when authenticated public access is
acceptable. Premium `allowed_ip_cidrs` creates a deny-by-default network rule
set and admits only those public IPv4 ranges, plus trusted services when the
bypass is enabled.

Private-only deployments must create a private endpoint and `privatelink.azurecr.io`
DNS integration outside this stack before disabling public access. Verify both
the registry control endpoint and regional data endpoint behavior from every
build and runtime network.

## Premium resilience and retention

Geo-replications copy registry content to additional regions and enable regional
endpoints. Do not repeat the primary `location`. Each replica can independently
request zone redundancy where supported. Replication is asynchronous; test
regional pull behavior and understand data-residency requirements.

Premium `retention_policy_in_days` removes untagged manifests. Deploy digests or
immutable release tags, and leave enough time for rollback and investigation.
Retention and external cleanup jobs should not both own the same artifact
lifecycle.

## Inputs and outputs

Required inputs are `subscription_id` and `project_name`. Variables cover
resource-group ownership, naming, location, tier, authentication, networking,
Premium controls, replicas, RBAC, environment, and tags. See `variables.tf` for
exact types and validation.

Outputs expose the registry resource ID, generated name, login server, managed
identity principal ID, and resource-group name.

## Cost, monitoring, and destroy behavior

The service tier, stored image layers, builds/tasks, replicas, data transfer,
private endpoints, and security scanning drive cost. Monitor storage, pull/push
failures, authentication failures, replication health, quota usage, and stale
artifacts. Validate cost and feature availability in every selected region.

`tofu destroy` removes a registry and all stored images. Geo-replication is not
a deletion backup. Copy required images to another registry and verify their
digests before destroying or replacing the resource.
