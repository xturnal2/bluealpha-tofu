# Azure virtual network

Creates an Azure virtual network with configurable subnets, optional subnet
delegations, a Network Security Group (NSG) per subnet, and an optional Standard
NAT Gateway for explicit outbound connectivity.

## Architecture

- one new or existing resource group;
- one VNet with one or more IPv4 address spaces and optional custom DNS servers;
- map-driven subnets with optional service endpoints and service delegations;
- by default, one empty NSG per subnet, retaining Azure's built-in deny-inbound
  and allow-outbound rules;
- optionally, one Standard NAT Gateway and static public IP associated with all
  or selected subnets.

The template does not add workload-specific NSG rules. Define those rules in the
workload stack after deciding which sources, ports, and protocols are required.

## Prerequisites and authentication

- OpenTofu 1.8 or newer
- an Azure subscription and permission to manage the selected resource group,
  virtual networks, NSGs, NAT Gateways, and public IP addresses
- Azure CLI authentication, a service principal, managed identity, or workload
  identity exposed through the standard `ARM_*` environment variables

For local Azure CLI authentication:

```bash
az login
export ARM_SUBSCRIPTION_ID="00000000-0000-0000-0000-000000000000"
```

Do not place client secrets in `.tfvars`.

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

Destroying a VNet fails while resources such as private endpoints, NICs, or
delegated services remain attached. Remove dependent workloads first.

## Important flags

| Flag | Default | Impact |
|---|---:|---|
| `create_resource_group` | `true` | Creates a dedicated group; set false with `resource_group_name` to reuse one |
| `create_network_security_groups` | `true` | Creates one empty NSG per subnet; Azure default rules remain active |
| `enable_nat_gateway` | `false` | Adds a stable outbound IP plus hourly and data-processing charges |
| `nat_gateway_subnet_names` | `[]` | Selects NAT-connected subnets; empty means every subnet |
| `nat_gateway_zones` | `[]` | Creates non-zonal NAT resources; one supported zone makes them zonal |
| `dns_servers` | `[]` | Uses Azure DNS; custom addresses replace the VNet DNS server list |

Each `subnets` entry also exposes:

- `service_endpoints` for selected Azure services;
- `default_outbound_access_enabled`, defaulting to `false`;
- `private_endpoint_network_policies`;
- `delegations` for services such as Container Apps or App Service.

Service endpoints do not give a service a private IP. Use Private Link/private
endpoints when traffic must remain on private addresses.

## Delegation example

```hcl
subnets = {
  container_apps = {
    address_prefixes = ["10.20.4.0/23"]
    delegations = {
      container_apps = {
        service_name = "Microsoft.App/environments"
      }
    }
  }
}
```

Confirm the service's required subnet size and delegation actions before apply.

## Inputs

| Name | Type | Default | Description |
|---|---|---:|---|
| `subscription_id` | `string` | `null` | Azure subscription; null uses `ARM_SUBSCRIPTION_ID` |
| `project_name` | `string` | required | Project identifier |
| `environment` | `string` | `"dev"` | Environment identifier |
| `location` | `string` | `"eastus"` | Azure region |
| `create_resource_group` | `bool` | `true` | Create or reuse a resource group |
| `resource_group_name` | `string` | `null` | Explicit resource group name |
| `vnet_address_space` | `list(string)` | `["10.0.0.0/16"]` | VNet IPv4 CIDRs |
| `dns_servers` | `list(string)` | `[]` | Custom DNS server IPv4 addresses |
| `subnets` | `map(object)` | app and data | Subnet CIDRs, endpoints, policies, and delegations |
| `create_network_security_groups` | `bool` | `true` | Add one NSG per subnet |
| `enable_nat_gateway` | `bool` | `false` | Add managed outbound connectivity |
| `nat_gateway_subnet_names` | `set(string)` | `[]` | Subnets associated with NAT |
| `nat_gateway_zones` | `list(string)` | `[]` | Optional single availability zone |
| `nat_gateway_idle_timeout_minutes` | `number` | `10` | NAT TCP idle timeout |
| `tags` | `map(string)` | `{}` | Additional tags |

## Outputs

`resource_group_name`, `virtual_network_id`, `virtual_network_name`,
`virtual_network_address_space`, `subnet_ids`, `subnet_address_prefixes`,
`network_security_group_ids`, `nat_gateway_id`, and `nat_public_ip_address`.

## Cost, security, and operations

VNets, subnets, and NSGs do not generally incur direct hourly charges. NAT
Gateway, its public IP, and processed data do. Availability-zone support varies
by region; leave `nat_gateway_zones` empty for a portable non-zonal deployment.

Empty NSGs are a boundary, not a complete workload policy. Add narrowly scoped
rules in consuming stacks. Keep state in an encrypted, access-controlled remote
backend, inspect every plan, and confirm address ranges do not overlap peered or
on-premises networks.
