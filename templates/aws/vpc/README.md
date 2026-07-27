# AWS VPC

Creates a multi-availability-zone VPC with separate public and private subnets.
Private subnets have no internet route by default. Optional NAT gateways provide
outbound internet access, and optional VPC flow logs provide network telemetry.

## Architecture

For each of two or three availability zones, the stack creates:

- one public subnet associated with a shared route table and internet gateway;
- one private subnet with a zone-specific route table;
- optionally, one NAT gateway per zone or one shared NAT gateway.

Instances do not receive public IPs automatically, even in public subnets.
Assign public addresses deliberately or place workloads behind a load balancer.

## Prerequisites and authentication

- OpenTofu 1.8 or newer
- an AWS account with permission to manage VPC, EC2 networking, IAM, and
  CloudWatch Logs resources used by the selected flags
- AWS credentials supplied through the standard environment, shared
  credentials file, AWS IAM Identity Center, or a workload identity

Do not place AWS access keys in `.tfvars`.

## Usage

```bash
cp example.tfvars terraform.tfvars
tofu init
tofu plan
tofu apply
```

To remove the stack:

```bash
tofu destroy
```

The VPC cannot be destroyed while resources outside this stack still use its
subnets, route tables, or security groups.

## Important flags

| Flag | Default | Impact |
|---|---:|---|
| `enable_nat_gateway` | `false` | Adds outbound internet access and hourly/data-processing charges |
| `single_nat_gateway` | `false` | Reduces NAT cost but introduces a single-zone dependency and possible cross-zone data charges |
| `enable_flow_logs` | `false` | Improves network visibility and adds CloudWatch ingestion/storage charges |
| `map_public_ip_on_launch` | `false` | Automatically gives instances in public subnets a public IPv4 address |
| `availability_zones` | `[]` | Pins exact zones instead of selecting available zones automatically |
| `public_subnet_cidrs` | `[]` | Overrides generated public CIDRs; requires one value per zone |
| `private_subnet_cidrs` | `[]` | Overrides generated private CIDRs; requires one value per zone |

For production resilience, enable NAT only when required and keep
`single_nat_gateway = false`. Consider VPC endpoints before sending
high-volume AWS service traffic through NAT.

## Inputs

| Name | Type | Default | Description |
|---|---|---:|---|
| `project_name` | `string` | required | Project identifier used in names and tags |
| `environment` | `string` | `"dev"` | Environment identifier |
| `aws_region` | `string` | `"us-east-1"` | AWS region |
| `vpc_cidr` | `string` | `"10.0.0.0/16"` | VPC IPv4 CIDR |
| `availability_zone_count` | `number` | `2` | Automatically selected zone count |
| `availability_zones` | `list(string)` | `[]` | Explicit list of two or three zones |
| `public_subnet_cidrs` | `list(string)` | `[]` | Custom public subnet CIDRs |
| `private_subnet_cidrs` | `list(string)` | `[]` | Custom private subnet CIDRs |
| `enable_nat_gateway` | `bool` | `false` | Add private outbound internet routes |
| `single_nat_gateway` | `bool` | `false` | Share one NAT gateway across zones |
| `enable_flow_logs` | `bool` | `false` | Send VPC flow logs to CloudWatch |
| `flow_log_retention_days` | `number` | `30` | CloudWatch log retention |
| `enable_dns_hostnames` | `bool` | `true` | Enable VPC DNS hostnames |
| `map_public_ip_on_launch` | `bool` | `false` | Automatically assign public IPs in public subnets |
| `tags` | `map(string)` | `{}` | Additional resource tags |

## Outputs

`vpc_id`, `vpc_cidr`, `availability_zones`, `public_subnet_ids`,
`private_subnet_ids`, `public_route_table_id`, `private_route_table_ids`,
`nat_gateway_ids`, and `flow_log_id`.

## Security and operations

This stack creates no workload security groups and no permissive ingress rules.
Add workload-specific security groups in consuming stacks with only the required
sources, protocols, and ports.

State can contain infrastructure identifiers and should use an encrypted,
access-controlled remote backend in team environments. Always inspect
`tofu plan`, and verify the generated CIDR layout does not overlap connected
networks before applying.
