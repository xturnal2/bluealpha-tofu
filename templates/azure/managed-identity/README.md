# Azure Managed Identity

Creates a user-assigned managed identity with optional OIDC federation and
least-privilege Azure RBAC assignments. It provides workload authentication
without client secrets, certificates, or credential values in OpenTofu state.

## Architecture

- optional resource group and one user-assigned managed identity;
- optional federated identity credentials for GitHub Actions, Kubernetes, or
  another standards-compliant OIDC issuer;
- optional RBAC assignments at explicit Azure resource scopes;
- no passwords, client secrets, certificates, or connection strings.

## Usage

```bash
az login
az account set --subscription 00000000-0000-0000-0000-000000000000
cp example.tfvars terraform.tfvars
tofu init
tofu plan
tofu apply
az identity show \
  --resource-group "$(tofu output -raw resource_group_name)" \
  --name example-api-dev-workload
```

The provisioning identity needs managed-identity write permission and role
assignment write permission wherever `role_assignments` are created.

## Important flags

| Flag | Default | Impact |
|---|---:|---|
| `identity_name` | generated | Stable name used when attaching the identity to Azure compute |
| `isolation_scope` | `null` | `Regional` limits use to a region where the feature is supported |
| `federated_credentials` | `{}` | Trusts exact external OIDC issuer/subject/audience combinations |
| `role_assignments` | `{}` | Grants the identity roles at explicit Azure scopes |

## OIDC federation

Federation exchanges a short-lived external OIDC token for an Azure access
token. It eliminates stored Azure client secrets, but its trust conditions are
the credential. Pin `issuer`, `subject`, and audience as narrowly as the issuer
supports.

For GitHub Actions, distinguish branch, tag, pull-request, and environment
subjects. Prefer protected GitHub environments for production and avoid broad
repository subjects that let untrusted branches assume privileged identities.
For Kubernetes, bind a specific cluster issuer, namespace, and service account.
Never reuse one high-privilege identity across unrelated repositories or
workloads.

Issuer URLs are normalized by removing a trailing slash. Changing issuer,
subject, or audience replaces the federated credential. Coordinate changes with
the workload to prevent an authentication outage.

## RBAC and identity IDs

The `principal_id` is the service-principal object ID used in Azure RBAC. The
`client_id` identifies which user-assigned identity Azure SDKs should select.
The `identity_id` is attached to Azure compute resources such as Container Apps,
Functions, and virtual machines. Do not interchange them.

Role assignments require explicit scopes and role names. Prefer data-plane roles
at the smallest resource scope, such as `Key Vault Secrets User`, `AcrPull`, or
`Storage Blob Data Reader`. Subscription-level Contributor or Owner should be
exceptional. Optional RBAC conditions must provide both `condition` and
`condition_version` and should be tested for service support.

RBAC and federated credential propagation are eventually consistent. CI and
applications should use bounded retries rather than creating long-lived fallback
credentials.

## Inputs and outputs

Required inputs are `subscription_id` and `project_name`. Variables cover
resource-group ownership, identity naming/location/isolation, federated trusts,
RBAC, environment, and tags. Outputs expose the resource, client, principal,
tenant, and federated credential IDs—never secrets.

## Cost, monitoring, and destroy behavior

Managed identity and federation generally have no direct per-identity charge;
target services and activity logs can incur cost. Monitor sign-ins, token
failures, federated credential changes, role assignment changes, unusual
resource access, and inactive identities.

Destroying the identity immediately breaks every attached compute resource,
federated workflow, and RBAC assignment. Inventory attachments and sign-ins,
migrate workloads to another identity, remove federation, and verify cutover
before deletion. Recreating the same name produces new client/principal IDs.
