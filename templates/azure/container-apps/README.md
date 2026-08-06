# Azure Container Apps

Runs a containerized application on Azure Container Apps with consumption-based
scaling, Log Analytics, a system-assigned identity, and internal HTTP ingress by
default.

## Architecture

- one new or existing resource group;
- Log Analytics workspace with configurable retention;
- dedicated Container Apps environment, optionally integrated with a delegated
  subnet and internal load balancer;
- one Container App with system-assigned identity, revisions, HTTPS ingress,
  HTTP concurrency scaling, and configurable replica bounds.

## Prerequisites and usage

```bash
az login
export ARM_SUBSCRIPTION_ID="00000000-0000-0000-0000-000000000000"
cp example.tfvars terraform.tfvars
tofu init
tofu plan
tofu apply
```

The image must be anonymously pullable. For private registries, extend the
template with managed-identity registry credentials or secret-backed registry
configuration appropriate to the registry.

## Important flags

| Flag | Default | Impact |
|---|---:|---|
| `min_replicas` | `0` | Permits scale-to-zero and cold starts |
| `max_replicas` | `3` | Bounds consumption cost and burst capacity |
| `external_ingress_enabled` | `false` | Keeps ingress internal to the environment |
| `enable_ingress` | `true` | Disable for background workers |
| `ingress_ip_restrictions` | `{}` | Adds named allow/deny CIDR rules |
| `internal_load_balancer_enabled` | `false` | Makes the environment internal and requires a delegated subnet |
| `zone_redundancy_enabled` | `false` | Improves environment resilience where supported and requires a subnet |
| `log_retention_days` | `30` | Controls Log Analytics retained data cost |

CPU and memory must use supported pairs: 0.25/0.5Gi, 0.5/1Gi, continuing in
0.25-core and 0.5Gi increments through 2/4Gi.

## Networking

Set `infrastructure_subnet_id` to a subnet delegated to
`Microsoft.App/environments`; the Azure VNet template supports arbitrary service
delegations. Confirm current subnet-size requirements before deployment.

Internal app ingress without an internal environment load balancer is reachable
from other apps in the environment. Use VNet integration plus
`internal_load_balancer_enabled` for private network clients.

## Secrets

`secrets` values are marked sensitive in the CLI but are stored in OpenTofu
state. Keep state encrypted and tightly access-controlled. Map container variable
names to secret keys through `secret_environment_variables`. Prefer Key Vault
references and managed identity when adapting the template for production.

## Inputs and outputs

Required inputs are `project_name` and `container_image`. Variables cover the
resource group, location, CPU/memory, replicas, revision mode, ingress, IP
restrictions, VNet integration, secrets, logs, and tags. See `variables.tf` for
exact types and validation.

Outputs include the environment/app IDs, app and revision names, ingress FQDN
and URL, managed identity principal ID, resource group, and Log Analytics ID.

## Cost, security, and destroy behavior

Replica CPU/memory time and Log Analytics ingestion/retention are the primary
costs. Scale-to-zero reduces idle compute but adds cold starts. Environment
networking features can add dedicated infrastructure charges.

Ingress always rejects insecure connections. Public ingress is opt-in, and an
empty restriction set permits all clients once public ingress is enabled. Add
Front Door/WAF or API Management when centralized edge controls are required.

`tofu destroy` removes the app, environment, and workspace. External container
images, VNets, subnets, and registries are not deleted.
