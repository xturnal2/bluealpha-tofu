# AWS CloudWatch metric alarm

Creates one static-threshold CloudWatch metric alarm with M-of-N evaluation and
separate ALARM, OK, and insufficient-data actions. A single alarm per stack
keeps its operational meaning, ownership, and lifecycle reviewable.

## Architecture and usage

The alarm evaluates one namespaced metric and exact dimension map using a
standard statistic. Copy `example.tfvars`, select a real metric/dimensions, then
run `tofu init`, `tofu plan`, and `tofu apply`. Connect `alarm_action_arns` to an
SNS topic or another action supported by CloudWatch.

## Important inputs

| Input | Default | Purpose |
|---|---:|---|
| `namespace` / `metric_name` | required | Identifies the metric. |
| `dimensions` | `{}` | Selects the exact resource time series. |
| `period_seconds` | `300` | Aggregation window. |
| `evaluation_periods` | `3` | Number of periods considered. |
| `datapoints_to_alarm` | `2` | Breaches required to alarm. |
| `treat_missing_data` | `missing` | Controls sparse/no-data behavior. |
| `alarm_action_arns` | `[]` | Routes the ALARM transition. |

## Cost, security, and operations

CloudWatch charges for alarms, high-resolution metrics, and related
notifications. The default five-minute period avoids high-resolution alarm
pricing. Validate missing-data behavior against metric semantics: `notBreaching`
can hide telemetry failure, while `breaching` can create noise. Route actions to
owned, least-privilege destinations and include a runbook in the description.
Test alarms safely after deployment and review thresholds as workload baselines
change.

## Outputs and destroy

Outputs return the alarm ARN, name, and ID. Destroy removes monitoring only; it
does not affect the measured resource or notification destination. Establish a
replacement before removing production coverage.
