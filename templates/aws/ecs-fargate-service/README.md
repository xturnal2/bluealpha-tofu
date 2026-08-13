# AWS ECS Fargate service

Runs one containerized HTTP service on ECS Fargate behind an Application Load
Balancer, with CloudWatch logs, deployment rollback, least-privilege task roles,
and optional CPU-based autoscaling.

## Architecture

- dedicated ECS cluster and task definition;
- internal Application Load Balancer by default;
- separate load balancer and task security groups;
- Fargate tasks in caller-provided subnets;
- CloudWatch Logs with configurable retention;
- task execution role for image pulls/logs and an empty application task role;
- optional HTTPS, ECS Exec, Container Insights, Fargate Spot, secrets, and
  autoscaling.

The stack accepts VPC and subnet IDs rather than remote-state references. Outputs
from `aws/vpc` can be passed directly by a root configuration or pipeline.

## Prerequisites and usage

Provide a VPC, two load balancer subnets in different availability zones, task
subnets, and a container image:

```bash
cp example.tfvars terraform.tfvars
tofu init
tofu plan
tofu apply
```

Private tasks need NAT or VPC endpoints for ECR/image registry access,
CloudWatch Logs, Secrets Manager/SSM, and ECS control-plane traffic. Do not set
`assign_public_ip = true` as a substitute for deliberate network design.

## Important flags

| Flag | Default | Impact |
|---|---:|---|
| `internal_load_balancer` | `true` | Keeps the ALB private; false creates an internet-facing endpoint |
| `allowed_ingress_cidrs` | `[]` | Empty denies CIDR ingress; public services commonly use `0.0.0.0/0` with HTTPS/WAF |
| `certificate_arn` | `null` | Enables TLS 1.2/1.3 on port 443 and optional HTTP redirect |
| `assign_public_ip` | `false` | Adds a public IP to every task ENI |
| `use_fargate_spot` | `false` | Reduces compute cost but tasks can be interrupted |
| `desired_count` | `1` | Controls baseline availability and compute cost |
| `enable_autoscaling` | `true` | Adjusts desired count based on CPU |
| `enable_container_insights` | `false` | Adds detailed telemetry and CloudWatch charges |
| `enable_execute_command` | `false` | Enables interactive ECS Exec and task-role SSM permissions |
| `additional_task_security_group_ids` | `[]` | Adds shared security-group identities for downstream services |
| `task_role_policy_statements` | `[]` | Adds explicit application actions and resource ARNs to the task role |

## Secrets and application permissions

`secrets` maps environment variable names to Secrets Manager or SSM parameter
ARNs. The execution role receives read access only to those ARNs. Customer-managed
KMS keys require a separate `kms:Decrypt` grant. Non-sensitive settings belong in
`environment_variables`.

The task role has no application permissions unless
`task_role_policy_statements` is populated. Each entry creates an Allow statement
with explicit actions and resources; wildcard access should be exceptional and
reviewed. The connected application-platform example demonstrates queue and
table permissions.

## Inputs

Core inputs are `project_name`, `vpc_id`, `load_balancer_subnet_ids`,
`task_subnet_ids`, and `container_image`. Runtime controls include `cpu`,
`memory`, `cpu_architecture`, `container_port`, `desired_count`,
`ephemeral_storage_gib`, and the autoscaling variables. Network/TLS controls are
`internal_load_balancer`, the allowed ingress collections, `assign_public_ip`,
`certificate_arn`, `redirect_http_to_https`, and
`additional_task_security_group_ids`. Application authorization is configured
through `task_role_policy_statements`. See `variables.tf` for exact types,
defaults, validation, and descriptions.

## Outputs

`cluster_arn`, `service_name`, `task_definition_arn`, `task_role_arn`,
`load_balancer_dns_name`, `service_url`, both security group IDs, and
`log_group_name`.

## Cost, security, and destroy behavior

Fargate task runtime, ALB hours/capacity units, CloudWatch Logs, NAT data, and
Container Insights are the primary costs. Fargate Spot is appropriate only for
interruptible workloads. Run at least two on-demand tasks across zones for
production availability.

HTTP is used between the ALB and tasks. Add end-to-end TLS if the workload's
threat model requires it. Apply WAF and organization-specific access logging at
the load balancer in a consuming stack.

`tofu destroy` stops the service and deletes its cluster, load balancer, log
group, and roles. External images, secrets, VPCs, and subnets are not deleted.
