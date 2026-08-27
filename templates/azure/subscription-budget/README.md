# Azure subscription budget

Creates a recurring Azure Cost Management budget for a subscription with
optional dimension or tag filters and actual or forecasted notifications. It is
an alerting control: reaching a threshold does not stop deployments, suspend
resources, or cap charges.

## Architecture

- One subscription-scoped cost budget.
- Monthly, quarterly, or annual recurrence.
- Explicit first-of-period start date and optional end date.
- Optional dimension and tag filters.
- One or more notifications to email, Azure Monitor action groups, or
  subscription role contacts.

Management-group and resource-group budgets, cost exports, anomaly alerts,
policy enforcement, and automated shutdown workflows remain separate.

## Prerequisites and authentication

- OpenTofu 1.8 or newer.
- Azure credentials allowed to read consumption data and manage subscription
  budgets.
- Existing action group resource IDs when `contact_groups` are used.
- A subscription offer that supports Azure Cost Management budgets.

Cost and forecast data can lag resource activity. Tag filters match only usage
records that contain the selected tags.

## Usage

```bash
cp example.tfvars terraform.tfvars
# Set start_date to the first day of the current or next billing month.
tofu init
tofu plan
tofu apply
```

Replace example contact addresses and dates before applying. Keep the start date
explicit so plans remain stable and reviewers can see the intended billing
period.

## Important inputs

| Input | Default | Purpose |
|---|---:|---|
| `amount` | `100` | Sets the recurring amount in subscription currency. |
| `time_grain` | `Monthly` | Chooses monthly, quarterly, or annual periods. |
| `start_date` | required | Anchors recurrence to a first-of-month UTC date. |
| `end_date` | Azure default | Optionally expires the budget. |
| `dimension_filters` | `{}` | Narrows costs by service, resource group, region, or other dimension. |
| `tag_filters` | `{}` | Narrows costs to selected allocation tags. |
| `notifications` | required | Sends actual or forecasted threshold alerts. |

## Cost considerations

The budget itself generally serves as a Cost Management control, while action
groups and their notification channels can have separate Azure Monitor charges.
All measured resources remain billable after a threshold is reached.

## Security and operations

- Send alerts to maintained distribution lists or action groups with an owned
  escalation path.
- Scope the deployment identity to budget management rather than broad
  subscription ownership when possible.
- Review filters after naming, tagging, or organizational changes. Missing tags
  can exclude real spend.
- Test action-group delivery and monitor muted or disabled notification paths.
- Treat forecasts as directional because delayed charges and rapid scale-out
  can materially change the result.

## Outputs

The stack returns the budget ID, name, recurring amount, and notification count.
It exposes no invoices, usage details, or credentials.

## Destroy behavior

Destroy removes the budget and all its notifications. It does not stop or
delete Azure resources and cannot reverse accrued charges. Establish replacement
cost monitoring before destroying a production budget.
