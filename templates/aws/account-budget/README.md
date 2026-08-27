# AWS account budget

Creates a recurring AWS cost budget with optional account, service, region, or
tag filters and actual or forecasted notifications. It is a financial
visibility control: reaching a threshold sends alerts but does not stop
resources or cap charges.

## Architecture

- One `COST` budget for the provider account or a specified member account.
- Monthly, quarterly, or annual recurrence.
- Optional AWS Budgets cost filters.
- Explicit charge-category inclusion settings.
- Actual and forecasted notifications delivered by email and/or SNS.

Budget actions, anomaly detection, cost-category definitions, tag activation,
and organization policies are intentionally outside this alerting template.

## Prerequisites and authentication

- OpenTofu 1.8 or newer.
- AWS billing access and permission to manage budgets and notifications.
- Payer-account authorization when `account_id` targets a linked account.
- Verified, correctly authorized SNS topics for SNS delivery.

Cost allocation tags must be activated in Billing before tag filters can match
charges. Billing data and forecasts can lag resource activity.

## Usage

```bash
cp example.tfvars terraform.tfvars
tofu init
tofu plan
tofu apply
```

Replace the example email address before applying. Choose thresholds that give
operators time to investigate—for example, an actual 80% warning and a
forecasted 100% warning.

## Important inputs

| Input | Default | Purpose |
|---|---:|---|
| `account_id` | provider account | Targets a linked/member account. |
| `limit_amount` | `100` | Sets the recurring cost limit. |
| `time_unit` | `MONTHLY` | Chooses monthly, quarterly, or annual periods. |
| `cost_filters` | `{}` | Narrows spend by tag, service, region, or other dimension. |
| `cost_types` | all common charges | Controls credits, taxes, support, refunds, and amortization. |
| `notifications` | `{}` | Sends actual or forecasted threshold alerts. |

## Cost considerations

AWS includes a limited number of budgets and charges for additional budgets or
some budget actions according to current account pricing. SNS delivery can also
incur small charges. The resources being measured remain billable after a
threshold is crossed.

## Security and operations

- Use distribution lists or monitored SNS topics instead of a single person's
  mailbox.
- Protect SNS topics with policies that allow the AWS Budgets service and only
  intended subscribers.
- Test notification routing and maintain an escalation runbook.
- Review filters when services, accounts, or cost-allocation tags change. An
  overly narrow filter can create false confidence.
- Treat forecasts as directional because new workloads and delayed billing data
  can change them quickly.

## Outputs

The stack returns the budget ID, ARN, name, and notification count. It exposes
no billing data or subscriber secrets.

## Destroy behavior

Destroy removes the budget and its notifications immediately. It does not
delete or stop any cloud resources and does not remove historical charges.
Create replacement monitoring before destroying a production budget.
