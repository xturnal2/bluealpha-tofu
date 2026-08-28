# AWS CloudWatch dashboard

Creates an operational CloudWatch dashboard from typed metric and Markdown
widgets. The template generates dashboard JSON so customers can configure
common views without hand-maintaining escaped JSON.

## Architecture and usage

Each metric widget displays one exact namespace, metric, and dimension set with
an optional threshold annotation. Text widgets add ownership, runbook, and
context. Copy `example.tfvars`, replace example dimensions and links, then run
`tofu init`, `tofu plan`, and `tofu apply`.

## Important inputs

| Input | Default | Purpose |
|---|---:|---|
| `default_time_range` | `-PT6H` | Initial relative time window. |
| `period_override` | `inherit` | Retains widget periods or selects automatic periods. |
| `metric_widgets` | `{}` | Defines metrics, grid positions, views, and annotations. |
| `text_widgets` | `{}` | Adds Markdown context and runbook links. |

## Cost, security, and operations

CloudWatch dashboards and metric retrieval can incur charges. Avoid overly
dense dashboards and high-frequency custom metrics. Dashboard access follows
IAM permissions; do not place secrets in Markdown because viewers and state can
expose it. Keep ownership and runbook links current, use stable resource
dimensions, and review widgets when resources are replaced.

## Outputs and destroy

Outputs return the dashboard ARN and name. Destroy removes only the view; it
does not remove metrics, alarms, logs, or monitored resources.
