# Azure Monitor metric alert

Creates one static-threshold Azure Monitor metric alert with one or more ANDed
criteria and reusable action-group routing. Keeping detection separate from the
action group allows notification ownership to evolve independently.

## Architecture and usage

The stack optionally creates a monitoring resource group, evaluates one or more
Azure resource scopes, and routes state changes to action groups. Copy
`example.tfvars`, replace the example resource ID and metric, then run
`tofu init`, `tofu plan`, and `tofu apply`. Use output from the Monitor action
group template as a key in `action_groups`.

## Important inputs

| Input | Default | Purpose |
|---|---:|---|
| `scopes` | required | Resources evaluated by the alert. |
| `criteria` | required | Metric namespace, aggregation, threshold, and dimensions. |
| `severity` | `2` | Classifies operational urgency from 0-4. |
| `frequency` | `PT5M` | Evaluation cadence. |
| `window_size` | `PT15M` | Aggregation window. |
| `auto_mitigate` | `true` | Resolves the state after recovery. |
| `action_groups` | `{}` | Routes alerts to shared receivers. |

## Cost, security, and operations

Azure Monitor metric alerts and action delivery can incur charges. Faster
frequencies and many time series increase evaluation volume. Use exact scopes
and dimensions, validate metric availability before setting
`skip_metric_validation`, and document a runbook in the description. Multiple
criteria are ANDed, which can reduce noise but may hide incidents if that is not
the intended logic. Test both firing and recovery paths.

## Outputs and destroy

Outputs return the metric alert ID, name, and resource group. Destroy removes
monitoring only and does not modify measured resources or shared action groups.
Create replacement coverage before deleting production alerts.
