# Azure custom RBAC role

Creates a least-privilege Azure custom role definition and optional assignments
at explicitly allowed scopes. The template starts with no permissions or
assignments, so users must state the management-plane or data-plane operations
the role genuinely requires.

## Architecture

- One custom role definition stored at a management-group, subscription,
  resource-group, or resource scope.
- One or more explicit assignable scopes.
- Management-plane `actions` and optional exclusions.
- Data-plane `data_actions` and optional exclusions.
- Optional assignments to users, groups, or service principals.

Microsoft Entra object creation, privileged identity management, access reviews,
deny assignments, and Azure Policy are separate governance concerns.

## Prerequisites and authentication

- OpenTofu 1.8 or newer.
- Azure credentials allowed to create custom role definitions and any requested
  assignments at every listed scope.
- Existing principal object IDs for assignments.

The default definition and assignable scope is the current subscription. The
deploying principal needs authorization at or above the definition scope.

## Usage

```bash
cp example.tfvars terraform.tfvars
tofu init
tofu plan
tofu apply
```

Start from observed job duties and use Azure provider-operation names. Test the
role in a non-production scope before extending `assignable_scopes` or assigning
it broadly.

## Important inputs

| Input | Default | Purpose |
|---|---:|---|
| `definition_scope` | subscription | Stores the custom role definition. |
| `assignable_scopes` | definition scope | Limits where the role can be assigned. |
| `actions` | `[]` | Allows management-plane operations. |
| `not_actions` | `[]` | Removes operations from broad management actions. |
| `data_actions` | `[]` | Allows supported resource data-plane operations. |
| `not_data_actions` | `[]` | Removes operations from broad data actions. |
| `role_assignments` | `{}` | Assigns the new role to exact principals and scopes. |

## Cost considerations

Custom roles and assignments have no direct hourly charge. The granted actions
can create, resize, or operate billable resources, so least privilege remains a
cost control as well as a security control.

## Security and operations

- Avoid wildcard actions unless exclusions and the resulting effective access
  have been carefully reviewed. `not_actions` is subtraction, not an explicit
  deny.
- Keep assignable scopes as narrow as operationally practical. Broad scopes
  allow future assignments outside the initial resource group.
- Assign groups rather than individuals for human access and govern membership
  through Entra processes.
- Conditions require both `condition` and `condition_version`; test them against
  the target resource provider.
- Review activity logs and access regularly. Custom roles do not automatically
  expire or require approval.

## Outputs

The stack returns the role definition resource ID, definition GUID, display
name, and optional assignment IDs. It exposes no tokens or credentials.

## Destroy behavior

OpenTofu removes assignments created here before deleting the custom role.
Assignments created elsewhere can block deletion and should be treated as an
ownership signal. Removing a role immediately revokes the permissions it
provided; migrate users and workloads before destroy.
