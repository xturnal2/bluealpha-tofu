# AWS IAM role

Creates a reusable IAM role with an explicit trust policy, optional permissions
boundary, and separately managed policy attachments. It is suitable for AWS
service workloads or cross-account access and defaults to granting no
permissions.

## Architecture

- One named IAM role with standard ownership tags.
- Trust statements for AWS services and/or IAM principals.
- Optional external-ID and MFA conditions for IAM-principal assumption.
- Optional permissions boundary.
- Managed policy attachments and validated inline policy JSON.

Instance profiles, OIDC/SAML providers, service-linked roles, and the policies
themselves remain separate. This keeps role trust distinct from workload
permissions and allows policy reuse.

## Prerequisites and authentication

- OpenTofu 1.8 or newer.
- AWS credentials allowed to create roles and attach the selected policies.
- Permission to pass the role is required in the workload stack, not here.

At least one trusted service principal or AWS principal ARN is required. Never
place AWS credentials or a sensitive external ID in committed variable files.

## Usage

```bash
cp example.tfvars terraform.tfvars
tofu init
tofu plan
tofu apply
```

Use `trusted_service_principals` for workloads such as ECS tasks or Lambda. Use
`trusted_aws_principal_arns` for controlled cross-account access, normally with
an `external_id` for third parties. Attach only the actions and resources the
workload needs.

## Important inputs

| Input | Default | Purpose |
|---|---:|---|
| `trusted_service_principals` | `[]` | Allows named AWS services to assume the role. |
| `trusted_aws_principal_arns` | `[]` | Allows specific accounts, roles, or users to assume it. |
| `external_id` | `null` | Adds third-party confused-deputy protection. |
| `require_mfa` | `false` | Requires MFA for IAM-principal assumption. |
| `permissions_boundary_arn` | `null` | Caps the role's effective permissions. |
| `managed_policy_arns` | `[]` | Attaches reusable managed policies. |
| `inline_policies` | `{}` | Adds role-specific JSON policies. |
| `force_detach_policies` | `false` | Detaches externally attached policies during destroy. |

## Cost considerations

IAM roles and policies do not have direct hourly charges. Services accessed by
the role can create costs, and overly broad permissions can increase the impact
of misuse. Review downstream service pricing and use budgets as a separate
control.

## Security and operations

- Trust and permission policies answer different questions: who may assume the
  role, and what the assumed role may do. Review both.
- Avoid trusting an entire external account unless its delegated role lifecycle
  is governed. Prefer exact role ARNs.
- Require an external ID for vendor access and rotate it through a secret
  channel; the value is sensitive in OpenTofu output and state.
- Use permissions boundaries and organization service-control policies for
  defense in depth.
- Keep session duration short for interactive and third-party roles.
- Monitor role assumption with CloudTrail and alert on unexpected principals.

## Outputs

The stack returns the role ARN, name, unique ID, and managed-policy attachment
IDs. It does not output the external ID or any credentials.

## Destroy behavior

OpenTofu removes attachments it owns before deleting the role. With
`force_detach_policies = false`, deletion fails when another system attached a
policy, preserving that ownership signal. Enable force detachment only after
confirming that removing external attachments is intentional.
