# AWS Lambda HTTP API

Deploys a packaged Lambda function behind an API Gateway v2 HTTP API with
structured function and access logs, throttling, and a least-privilege service
trust relationship. A small Python JSON endpoint is included so the stack can
be evaluated immediately.

## Architecture

- Lambda execution role with CloudWatch Logs access and optional VPC/X-Ray
  permissions;
- Lambda function built from `src/index.py` by the Archive provider;
- API Gateway HTTP API with a `$default` route and auto-deployed stage;
- API-to-Lambda invoke permission;
- JSON function logs and structured API access logs with configurable retention.

## Prerequisites and usage

```bash
aws sts get-caller-identity
cp example.tfvars terraform.tfvars
tofu init
tofu plan
tofu apply
curl "$(tofu output -raw api_endpoint)"
```

AWS credentials can come from environment variables, a shared profile, workload
identity, or another standard AWS provider credential source.

Replace `src/index.py` with application code or point `source_file` at another
single-file handler. Update `runtime` and `handler` together when changing
languages or filenames. Applications with dependencies or multiple files should
replace the `archive_file` data source with their build artifact or deployment
pipeline; infrastructure provisioning is not a substitute for a reproducible
application build.

## Important flags

| Flag | Default | Impact |
|---|---:|---|
| `architecture` | `arm64` | Arm can reduce cost; dependencies must support the architecture |
| `memory_size` | `128` | Controls memory and proportional CPU allocation |
| `timeout_seconds` | `10` | Bounds execution time and runaway request cost |
| `reserved_concurrent_executions` | `-1` | Reserves capacity, caps concurrency, or disables the function with `0` |
| `throttle_rate_limit` | `50` | Bounds steady API requests per second |
| `throttle_burst_limit` | `100` | Bounds short request bursts |
| `cors_allowed_origins` | `[]` | Enables API-managed browser CORS only when populated |
| `tracing_mode` | `PassThrough` | `Active` enables X-Ray and attaches write permissions |
| `vpc_subnet_ids` | `[]` | Attaches Lambda to a VPC and can add cold-start/network complexity |
| `log_retention_days` | `30` | Controls function and API log storage cost |

## Public access, CORS, and authorization

The generated API endpoint is public and the `$default` route uses no
authorizer. Throttling limits traffic rate but does not authenticate callers or
absorb every denial-of-service scenario. Add a JWT/Lambda authorizer, IAM
authorization, or an edge layer such as CloudFront and AWS WAF before using the
template for protected operations.

CORS is a browser policy, not access control. Leave `cors_allowed_origins` empty
when browser cross-origin access is unnecessary. Never combine wildcard origins
with credentialed CORS; the template rejects that configuration.

## VPC networking

Set both `vpc_subnet_ids` and `vpc_security_group_ids` to attach the function to
a VPC. Use private subnets. A VPC-attached function needs a NAT gateway or VPC
endpoints to reach public AWS/service endpoints, and its security group and
routes must permit required destinations. The stack attaches AWS's managed
Lambda VPC access policy only when VPC networking is enabled.

## Secrets and permissions

`environment_variables` is marked sensitive in CLI output, but its values remain
in OpenTofu state and Lambda configuration. Prefer Secrets Manager or Parameter
Store and grant only the exact read actions/resources your function needs. Add
application-specific IAM statements to the execution role; this template grants
only logging plus optional VPC-network-interface and X-Ray access.

## Inputs and outputs

Only `project_name` is required. Variables cover source/runtime, architecture,
memory, timeout, temporary storage, concurrency, environment values, logs,
tracing, VPC attachment, CORS, throttling, region, environment, and tags. See
`variables.tf` for exact types and validation.

Outputs include the API endpoint and ID, function name and ARN, execution role
ARN, and both CloudWatch log group names.

## Cost, operations, and destroy behavior

Lambda requests/duration, API requests, CloudWatch logs/metrics, X-Ray traces,
and any VPC NAT traffic drive cost. HTTP API detailed metrics are enabled.
Monitor errors, throttles, duration, concurrent executions, API 4xx/5xx rates,
integration latency, and log ingestion.

`tofu destroy` removes the API, function, role, and log groups, including their
retained log data. The locally generated `lambda.zip` is ignored by Git and may
remain until manually removed. External VPC resources are never deleted.
