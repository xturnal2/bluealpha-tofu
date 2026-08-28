# Azure Monitor action group

Creates a reusable Azure Monitor notification route with email and HTTPS
webhook receivers. Action groups are intentionally separate from alert rules so
teams can update routing without rebuilding detection logic.

## Architecture and usage

The stack optionally creates a resource group, then one enabled action group.
Email and webhook receivers use Azure's common alert schema by default. Copy
`example.tfvars`, replace the example contact, then run `tofu init`, `tofu plan`,
and `tofu apply`. Pass `action_group_id` to metric, activity-log, or scheduled
query alert stacks.

## Important inputs

| Input | Default | Purpose |
|---|---:|---|
| `create_resource_group` | `true` | Creates or reuses the monitoring group. |
| `short_name` | `platform` | Compact notification identifier. |
| `enabled` | `true` | Globally enables receiver delivery. |
| `email_receivers` | `{}` | Routes alerts to monitored mailboxes. |
| `webhook_receivers` | `{}` | Routes common-schema payloads to HTTPS endpoints. |

## Cost, security, and operations

Action-group notification channels can incur Azure Monitor charges. Webhook
endpoints must use HTTPS; do not embed tokens in URLs because values are stored
in OpenTofu state. Prefer Entra-authenticated webhooks where supported. Use
distribution lists rather than individuals, test receiver delivery, document
escalation ownership, and temporarily set `enabled = false` only through a
reviewed maintenance process.

## Outputs and destroy

Outputs return the action group ID, name, and resource group. Destroy removes
the notification route and may leave alerts without actions; migrate all alert
references first. If this stack created the resource group, unrelated resources
must not be placed there.
