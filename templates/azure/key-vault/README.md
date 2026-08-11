# Azure Key Vault

Creates an RBAC-authorized Azure Key Vault with soft delete and purge protection
enabled, legacy deployment integrations disabled, and no stored secret values.
The stack can assign narrowly scoped data-plane roles and restrict the public
endpoint by IPv4 CIDR or virtual-network service endpoint.

## Architecture

- an optional resource group and one Azure Key Vault;
- Microsoft Entra RBAC authorization instead of legacy access policies;
- 90-day soft-delete retention and purge protection by default;
- authenticated public endpoint with optional deny-by-default network ACLs;
- optional vault-scoped RBAC assignments for application and operator identities.

The template intentionally creates the vault boundary, not secrets, keys, or
certificates. Secret values in OpenTofu resources are stored in state even when
marked sensitive. Applications and deployment systems should populate values
through a controlled secret-management workflow after the vault exists.

## Prerequisites and usage

```bash
az login
az account set --subscription 00000000-0000-0000-0000-000000000000
cp example.tfvars terraform.tfvars
tofu init
tofu plan
tofu apply
az keyvault show --name "$(tofu output -raw vault_name)"
```

The provisioning identity needs resource creation permissions and
`Microsoft.Authorization/roleAssignments/write` when `role_assignments` is
non-empty. Changing the vault permission model also requires unrestricted role
assignment permissions, so this template creates new vaults in RBAC mode and
does not switch existing access-policy vaults implicitly.

## Important flags

| Flag | Default | Impact |
|---|---:|---|
| `sku_name` | `standard` | Premium supports HSM-backed keys and has higher cost; secret storage behavior is otherwise similar |
| `soft_delete_retention_days` | `90` | Keeps deleted vaults and objects recoverable for 7-90 days |
| `purge_protection_enabled` | `true` | Blocks permanent purge until retention expires and cannot be disabled after enablement |
| `public_network_access_enabled` | `true` | Exposes an authenticated endpoint; disable only after private endpoint/DNS setup |
| `allowed_ip_cidrs` | `[]` | Non-empty values switch the public network ACL to deny by default |
| `allowed_subnet_ids` | `[]` | Permits subnets configured with the Key Vault service endpoint |
| `trusted_services_bypass_enabled` | `true` | Allows designated Azure services through network ACLs; RBAC still applies |
| `enabled_for_*` | `false` | Opts into legacy VM, disk encryption, or ARM deployment retrieval paths |
| `role_assignments` | `{}` | Grants named Entra principals vault-scoped roles without creating credentials |

## RBAC and application access

The vault always uses Azure RBAC. `Key Vault Secrets User` is the assignment
default for runtime secret reads. Use `Key Vault Secrets Officer` for identities
that manage secret values, `Key Vault Crypto User` for application key
operations, and administrative roles only for tightly controlled operators.
Separate control-plane administration from data-plane access and keep roles at
vault scope unless a narrower object scope is deliberately managed elsewhere.

Role assignment changes can take several minutes to propagate. Workloads should
use managed identity or workload identity rather than client secrets. The
`principal_id` is an object ID, not an application/client ID.

## Network model

Public network access does not bypass Entra authentication or RBAC. With no
allowlists, authenticated clients can reach the endpoint from public networks.
Adding any IP or subnet entry changes `default_action` to `Deny`, permitting
only configured networks and the optional trusted-services bypass.

Subnet entries require the `Microsoft.KeyVault` service endpoint. For stronger
private isolation, manage a private endpoint and the `privatelink.vaultcore.azure.net`
private DNS zone in a connected network stack, verify resolution and access,
then set `public_network_access_enabled = false`.

Network restrictions affect both workloads and operators. Ensure CI runners,
break-glass operators, and rotation automation have a tested path before
enabling deny-by-default rules.

## Recovery and irreversible choices

Soft delete retains deleted vaults and objects for the configured window. Purge
protection prevents early permanent deletion and is enabled by default. Azure
does not allow purge protection to be turned off after it is enabled. This is a
deliberate production-safe default, but it means the globally unique vault name
cannot be immediately reused after deletion.

Recovery is not a complete backup strategy. Test secret/key/certificate
recovery, record object versions where required, and use supported backup or
replication processes for disaster-recovery requirements.

## Inputs and outputs

Required inputs are `subscription_id` and `project_name`; `tenant_id` defaults
to the authenticated tenant. Variables cover resource-group ownership, naming,
tier, retention/protection, networking, deployment integrations, RBAC,
environment, and tags. See `variables.tf` for exact validation.

Outputs expose the vault ID, generated name, data-plane URI, tenant ID, and
resource-group name. No secret values or credentials are returned.

## Cost, monitoring, and destroy behavior

Operations, stored secret/certificate versions, Premium HSM keys, private
endpoints, logging, backups, and cross-region architecture drive cost. Enable
diagnostic settings in your observability stack and monitor denied requests,
throttling, expiring secrets/certificates, role changes, network ACL changes,
deletes, recoveries, and purge attempts.

`tofu destroy` deletes the active vault, but soft delete retains it. With purge
protection enabled, it cannot be permanently purged or recreated under the same
name until the retention period expires. Remove or migrate dependent workloads
and verify recovery requirements before destroy.
