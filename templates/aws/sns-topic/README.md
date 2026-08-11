# AWS SNS Topic

Creates an encrypted Amazon SNS topic with optional FIFO ordering, subscriptions,
filter policies, dead-letter routing, message archiving, and explicit publisher
principals. The default standard topic has no subscribers or public publishers,
uses the AWS-managed SNS KMS key, and signs HTTP notifications with SHA-256.

## Architecture

- one standard or FIFO SNS topic;
- server-side encryption with the AWS-managed SNS key by default;
- optional protocol subscriptions with filters and DLQ redrive policies;
- optional FIFO content-based deduplication and message archive;
- optional resource policy granting only `sns:Publish` to named IAM principals.

Endpoint resource policies and permissions remain with their owning stacks. For
example, an SQS subscription requires the queue to allow this topic ARN, and a
Lambda subscription requires an invocation permission for SNS.

## Prerequisites and usage

```bash
aws sts get-caller-identity
cp example.tfvars terraform.tfvars
tofu init
tofu plan
tofu apply
aws sns get-topic-attributes --topic-arn "$(tofu output -raw topic_arn)"
```

AWS credentials can come from environment variables, a shared profile, workload
identity, or another standard AWS provider credential source.

## Important flags

| Flag | Default | Impact |
|---|---:|---|
| `fifo_topic` | `false` | Adds ordered delivery/deduplication semantics and restricts supported subscriber protocols |
| `content_based_deduplication` | `false` | FIFO-only; derives deduplication IDs from the message body |
| `kms_master_key_id` | `alias/aws/sns` | Encrypts messages at rest; a customer key adds policy control and KMS cost |
| `signature_version` | `2` | Uses SHA-256 for HTTP/S notification signatures |
| `tracing_config` | `PassThrough` | `Active` creates X-Ray segments and can add tracing cost |
| `archive_policy_days` | `null` | FIFO-only message archive for replay; adds archive storage and replay cost |
| `subscriptions` | `{}` | Creates fan-out endpoints, filters, and optional DLQ routing |
| `allowed_publisher_principal_arns` | `[]` | Adds resource-policy publish access for only the named IAM principals |

## Standard versus FIFO

Standard topics maximize throughput and provide at-least-once delivery with
best-effort ordering. Consumers must be idempotent. FIFO topics provide ordered
message groups and deduplication, but require FIFO-compatible downstream
services and publishers to supply message group IDs. The template appends
`.fifo` automatically, so `topic_name` must omit that suffix.

Content-based deduplication hashes the message body, not message attributes. It
can incorrectly collapse messages that share a body but differ in attributes;
publish an explicit deduplication ID when that distinction matters.

## Subscriptions, filters, and delivery failures

Subscriptions use stable map keys so adding one does not reorder others. Filter
policies can inspect `MessageAttributes` or `MessageBody`. Keep policies narrow,
version event contracts, and monitor filtered-out notifications as well as
delivery failures.

SQS, Lambda, and Firehose endpoints normally confirm automatically after their
resource permissions are correct. HTTP/S and email protocols may remain pending
until the endpoint owner confirms them. OpenTofu cannot complete an out-of-band
email click. `endpoint_auto_confirms` should be used only when an HTTP endpoint
actually implements SNS confirmation.

`dead_letter_queue_arn` configures the subscription redrive policy, but the DLQ
must separately allow SNS to send messages. The repository's SQS template can
accept this topic ARN through `allowed_sns_topic_arns`.

## Encryption, policies, and signatures

The AWS-managed SNS KMS key is the simple encrypted default. A customer-managed
key needs key-policy permissions for SNS and all publishing services; service
publishers can fail even when the topic policy allows them if KMS access is
missing.

Same-account workloads can receive `sns:Publish` in their identity policies.
Use `allowed_publisher_principal_arns` primarily for explicit cross-account
access. When set, the template preserves owner administration and adds a
publish-only statement. Service principals with source-ARN conditions require
a purpose-built topic policy and are intentionally not generalized here.

HTTP/S consumers must validate the SNS signing certificate URL, certificate
chain, signature, topic ARN, and expected message type before processing. Do not
disable authentication merely because SNS signs messages.

## Inputs and outputs

Only `project_name` is required. Variables cover naming, topic type,
deduplication, KMS, signatures, tracing, archives, subscriptions, publishers,
region, environment, and tags. See `variables.tf` for exact validation.

Outputs expose the topic ARN/name/owner and subscription ARNs keyed by their
configured labels.

## Cost, monitoring, and destroy behavior

Requests, delivered notifications, payload size, internet/SMS delivery, KMS,
X-Ray, FIFO archive storage/replay, SQS queues, and delivery retries drive cost.
Monitor publish failures, delivery failures, DLQ depth, message age, throttles,
filter outcomes, archive size, and downstream latency.

`tofu destroy` deletes the topic and managed subscriptions. It does not delete
downstream queues, functions, delivery streams, or DLQs. Pending or externally
created subscriptions may need separate cleanup. Preserve event audit data and
drain publishers before deletion.
