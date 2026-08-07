# Azure Functions HTTP

Creates a Linux Azure Function App with runtime storage, a hosting plan,
workspace-based Application Insights, structured monitoring, managed identity,
and configurable HTTP access controls. A Python v2 programming-model health
endpoint is included as a separate application sample.

## Architecture

- one new or existing resource group;
- globally unique StorageV2 account for Functions host state and content;
- Linux Consumption, Elastic Premium, or supported dedicated App Service plan;
- Linux Function App with HTTPS-only access, disabled basic publishing
  credentials, system-assigned identity, and configurable runtime;
- Log Analytics workspace and Application Insights with retention, sampling,
  and a daily ingestion cap;
- optional IP restrictions, CORS, outbound VNet integration, health check, and
  scale settings.

## Prerequisites and infrastructure usage

```bash
az login
export ARM_SUBSCRIPTION_ID="00000000-0000-0000-0000-000000000000"
cp example.tfvars terraform.tfvars
tofu init
tofu plan
tofu apply
```

The default example includes a documentation-only IP allow-list address. Replace
`203.0.113.10/32` with a real caller CIDR or clear `ip_restrictions` for initial
testing.

## Publish the included sample

Infrastructure and application releases are deliberately separate. Install
Azure Functions Core Tools, then publish the Python sample after `tofu apply`:

```bash
cd sample
func azure functionapp publish "$(tofu -chdir=.. output -raw function_app_name)" --python
curl "$(tofu -chdir=.. output -raw sample_health_url)"
```

On PowerShell, assign the output to a variable instead of using `$(...)` if
preferred. The sample targets the default Python runtime. When selecting Node,
.NET isolated, or PowerShell, deploy an application built for that runtime.

## Important flags

| Flag | Default | Impact |
|---|---:|---|
| `plan_sku_name` | `Y1` | Consumption minimizes idle cost; Premium/dedicated tiers change scaling and features |
| `runtime_name` / `runtime_version` | `python` / `3.13` | Must match the deployed application and a version available in the region |
| `always_on` | `false` | Reduces cold starts on supported paid plans; invalid on Y1 |
| `maximum_instance_count` | `null` | Caps scale-out where the selected plan supports it |
| `pre_warmed_instance_count` | `null` | Reduces Premium cold starts and increases minimum cost |
| `storage_replication_type` | `LRS` | Changes storage resilience, availability, and cost |
| `ip_restrictions` | `{}` | Adds ordered inbound allow/deny rules; rules default unmatched traffic to Deny |
| `public_network_access_enabled` | `true` | Disabling requires a separately managed private endpoint and DNS |
| `virtual_network_subnet_id` | `null` | Enables outbound VNet integration and may affect egress routing |
| `log_retention_days` | `30` | Controls telemetry retention cost |
| `application_insights_daily_cap_gb` | `1` | Caps daily Insights ingestion to bound observability cost |

Plan SKUs, runtime versions, VNet integration, scale settings, and zone behavior
vary by region and plan family. Confirm current availability before applying.

## Public access, restrictions, and authentication

The platform endpoint is public by default so it can serve HTTP traffic. The
included health function permits anonymous calls. An empty `ip_restrictions` map
allows all callers. When rules are present, unmatched requests default to Deny;
set `ip_restriction_default_action = "Allow"` only when deliberately building a
deny list.

IP restrictions and CORS do not replace authentication. Add function keys,
App Service Authentication with Microsoft Entra ID, API Management, or another
application-appropriate identity layer for protected operations. CORS is only a
browser policy, and wildcard origins cannot be combined with credentials.

Setting `public_network_access_enabled = false` does not create private access.
Add a private endpoint and `privatelink.azurewebsites.net` DNS outside this
stack before disabling the public endpoint.

## Networking and storage

`virtual_network_subnet_id` is outbound regional VNet integration, not inbound
private connectivity. The subnet must meet Azure's delegation and size rules.
Set `vnet_route_all_enabled` to send all app egress through that integration;
ensure routes, DNS, NSGs, NAT, and service endpoints/private endpoints preserve
access to every dependency.

The runtime storage account uses shared-key access because the Linux Function
App resource consumes its access key. That key is stored in OpenTofu state.
Restrict and encrypt state, and evaluate managed-identity storage access plus
private storage networking when adapting the stack for regulated workloads.

## Application settings and identity

`application_settings` values are marked sensitive but remain in state and the
Function App configuration. Prefer Key Vault references and grant the
system-assigned identity narrowly scoped access. The template reserves
`FUNCTIONS_WORKER_RUNTIME`; a user-supplied value with the same key overrides it,
so keep it consistent with `runtime_name`.

## Inputs and outputs

Only `project_name` is required. Variables cover resource placement, naming,
plan sizing, runtime, scale, storage replication, application settings, public
access, IP rules, CORS, outbound VNet integration, monitoring, and tags. See
`variables.tf` for exact types and validation.

Outputs include app IDs/names, hostname, base and sample URLs, managed identity,
storage account, Application Insights, Log Analytics, and resource group.

## Cost, operations, and destroy behavior

Function execution, minimum Premium/dedicated instances, storage transactions,
Log Analytics ingestion/retention, and Application Insights drive cost. Monitor
function failures, duration, throttles, instance count, dependency failures,
storage latency, telemetry cap events, and HTTP 4xx/5xx responses.

`tofu destroy` removes the Function App, plan, storage account and its contents,
Application Insights, and Log Analytics data. It does not delete external VNets,
subnets, private endpoints, or application artifacts outside Azure. Export
required telemetry or storage data before destroying the stack.
