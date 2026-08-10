# AWS SQS Queue

Creates an encrypted Amazon SQS queue with long polling and a restricted
dead-letter queue by default. Standard and FIFO workloads are supported without
introducing a custom wrapper or application-specific IAM roles.

## Architecture

- one standard or FIFO source queue;
- SQS-managed server-side encryption by default, with optional customer-managed
  KMS encryption;
- matching dead-letter queue with a redrive allow policy restricted to the
  source queue;
- optional SNS send policy restricted to explicitly listed topic ARNs;
- configurable retention, visibility timeout, delay, polling, message size, and
  FIFO throughput behavior.

## Prerequisites and usage

```bash
aws sts get-caller-identity
cp example.tfvars terraform.tfvars
tofu init
tofu plan
tofu apply
aws sqs get-queue-attributes \
  --queue-url "$(tofu output -raw queue_url)" \
  --attribute-names All
```

AWS credentials can come from environment variables, a shared profile, workload
identity, or another standard AWS provider credential source.

## Important flags

| Flag | Default | Impact |
|---|---:|---|
| `create_dead_letter_queue` | `true` | Preserves repeatedly failing messages for diagnosis and redrive |
| `max_receive_count` | `5` | Controls how quickly poison messages move to the DLQ |
| `visibility_timeout_seconds` | `30` | Should exceed normal consumer processing time |
| `receive_wait_time_seconds` | `20` | Enables long polling to reduce empty receives and request cost |
| `message_retention_seconds` | `345600` | Retains source messages for four days by default |
| `dead_letter_retention_seconds` | `1209600` | Retains failed messages for the 14-day maximum |
| `fifo_queue` | `false` | Enables ordering and deduplication, changing producer requirements and throughput |
| `high_throughput_fifo` | `false` | Uses per-message-group deduplication and throughput |
| `kms_master_key_id` | `null` | Selects a customer-managed key instead of SQS-managed encryption |
| `allowed_sns_topic_arns` | `[]` | Grants only listed SNS topics permission to send messages |

Current queue attribute limits and behaviors are documented in the
[AWS CreateQueue API reference](https://docs.aws.amazon.com/AWSSimpleQueueService/latest/APIReference/API_CreateQueue.html).

## FIFO behavior

Set `fifo_queue = true` when consumers require ordered processing within message
groups. Producers must include a message group ID. They must also include a
deduplication ID unless `content_based_deduplication` is enabled.

`high_throughput_fifo = true` sets deduplication scope to `messageGroup` and the
throughput limit to `perMessageGroupId`, the paired settings AWS requires for
high-throughput FIFO. Use sufficiently distributed group IDs or a single busy
group will still serialize processing.

Changing an existing queue between standard and FIFO changes its name and
forces replacement. Plan producers and consumers before applying that change.

## Delivery and failure handling

SQS standard queues use at-least-once delivery. Consumers must be idempotent and
delete a message only after successful processing. FIFO deduplication does not
remove the need for idempotent downstream writes.

Set `visibility_timeout_seconds` longer than typical processing, or extend
visibility while processing. A timeout that is too short causes concurrent
redelivery; one that is too long delays recovery after a failed consumer.

The DLQ retains messages longer than the source queue by default. Alarm on DLQ
message count and oldest-message age outside this template, inspect failures,
fix the consumer, and redrive deliberately. Disabling the DLQ discards this
isolation mechanism and leaves messages cycling until source retention expires.

## Encryption and IAM

SQS-managed server-side encryption is enabled by default. When
`kms_master_key_id` is set, producers and consumers also need the appropriate
KMS permissions and the key policy must trust them. KMS API usage and key cost
vary with `kms_data_key_reuse_period_seconds`.

The template does not create producer or consumer identities. Grant application
roles only the required actions against output `queue_arn`. When
`allowed_sns_topic_arns` is populated, the resource policy permits
`sqs:SendMessage` only from those exact SNS source ARNs.

## Inputs and outputs

Only `project_name` is required. Variables cover naming, FIFO behavior, delivery
timing, retention, message size, DLQ redrive, encryption, SNS integration,
region, environment, and tags. See `variables.tf` for exact types and validation.

Outputs include the source queue name, ARN, and URL plus nullable DLQ equivalents.

## Cost, monitoring, and destroy behavior

API requests, payload chunks, data transfer, and optional customer-managed KMS
calls drive cost. Long polling reduces empty receive requests. Monitor visible
and in-flight messages, oldest-message age, delayed messages, sent/received/
deleted counts, DLQ depth, and KMS failures.

`tofu destroy` permanently deletes both queues and every message they contain.
OpenTofu cannot drain or archive them first. Stop producers, preserve required
messages, and verify downstream recovery procedures before destroying or
replacing a queue.
