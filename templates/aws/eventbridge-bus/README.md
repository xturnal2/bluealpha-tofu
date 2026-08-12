# AWS EventBridge Bus

Creates a custom Amazon EventBridge event bus with optional cross-account
publishers, customer-managed encryption, an SQS dead-letter queue for encrypted
bus failures, and an optional replay archive.

## Architecture

- one custom event bus with an AWS-owned encryption key by default;
- optional publish-only resource policy for explicit IAM principals;
- optional customer-managed KMS encryption and related SQS DLQ;
- optional filtered archive with configurable retention.

Rules and targets are intentionally owned by workload stacks. This keeps the bus
as a stable contract while consumers deploy independently.

## Usage

```bash
aws sts get-caller-identity
cp example.tfvars terraform.tfvars
tofu init
tofu plan
tofu apply
aws events describe-event-bus --name "$(tofu output -raw event_bus_name)"
```

## Important flags

| Flag | Default | Impact |
|---|---:|---|
| `kms_key_identifier` | `null` | Uses an AWS-owned key; a customer key adds policy obligations and KMS cost |
| `dead_letter_queue_arn` | `null` | Captures bus-level failures associated with customer-managed encryption |
| `allowed_put_events_principal_arns` | `[]` | Grants publish-only bus access to explicit IAM principals |
| `enable_archive` | `false` | Stores matching events for replay and adds archive/replay cost |
| `archive_retention_days` | `30` | Controls archive retention; null retains indefinitely |
| `archive_event_pattern` | `{}` | Empty selects every event; narrow patterns reduce data exposure and cost |

## Publishing and authorization

Same-account publishers normally receive `events:PutEvents` through identity
policies scoped to `event_bus_arn`. Use the bus policy for cross-account access
or centrally governed principals. It grants only publishing, not rule, archive,
replay, or bus administration.

Publishers should use versioned `source` and `detail-type` conventions and put
schema versions in event detail. EventBridge provides at-least-once delivery;
targets must be idempotent and validate every event rather than trusting the bus
as an authorization boundary.

## Encryption, DLQ, and archive

An AWS-owned key is the simplest encrypted default. A customer key must allow
EventBridge and relevant principals, and a restrictive key policy can stop
publishing, routing, or replay. The optional bus DLQ is relevant to failures
caused by customer-managed encryption; target delivery DLQs belong on rules.
The queue policy and KMS policy must separately permit EventBridge.

Archives allow replay after consumer recovery or rule correction. Replay emits
events again and can duplicate side effects, so consumers need idempotency keys.
Archive retention and patterns should follow data classification requirements;
an empty pattern may capture sensitive details from every producer.

## Inputs and outputs

Only `project_name` is required. Variables cover naming, encryption, DLQ,
publishers, archive filtering/retention, region, environment, and tags. Outputs
expose the bus name/ARN and nullable archive ARN.

## Cost, monitoring, and destroy behavior

Custom events, cross-account delivery, archives, replays, KMS, SQS, rules, and
targets drive cost. Monitor failed invocations, throttles, DLQ depth, archive
size, replay status, policy/key changes, and schema drift.

Destroying the bus removes its managed archive and resource policy. Existing
workload-owned rules must be removed or migrated, publishers stopped, and any
required event history exported before destruction.
