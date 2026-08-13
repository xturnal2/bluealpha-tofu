# Azure DNS zone

Creates a public Azure DNS zone with optional `A`, `AAAA`, `CNAME`, and `TXT`
records plus zone-scoped RBAC. It exposes authoritative name servers so the
parent zone or registrar can delegate the domain explicitly.

## Architecture

- An optional dedicated resource group.
- One global Azure public DNS zone.
- Optional IPv4 and IPv6 records using literal addresses or supported Azure
  resource aliases.
- Optional CNAME and TXT records.
- Optional start-of-authority timing customization.
- Optional least-privilege role assignments scoped to the zone.

Private DNS, DNS Resolver, DNSSEC, traffic routing, health probes, and registrar
integration are intentionally separate because they require different network,
security, and ownership decisions.

## Prerequisites and authentication

- OpenTofu 1.8 or newer.
- An Azure subscription and a principal allowed to create resource groups, DNS
  zones, record sets, and requested role assignments.
- Control of the parent DNS zone or registrar for delegation.
- Azure authentication configured through the CLI, workload identity, managed
  identity, or service-principal environment—not in variable files.

## Usage

```bash
cp example.tfvars terraform.tfvars
tofu init
tofu plan
tofu apply
```

After apply, delegate the zone to every value in `name_servers`. DNS clients do
not use the new zone until the parent NS change propagates.

Record names are relative to the zone: use `@` for the apex, `www` for a host,
and `_service` for a verification label. TXT values are plain strings; the
provider handles DNS presentation formatting.

## Important inputs

| Input | Default | Purpose |
|---|---:|---|
| `zone_name` | required | Public DNS suffix managed by Azure DNS. |
| `create_resource_group` | `true` | Creates or reuses a DNS resource group. |
| `a_records` | `{}` | Creates IPv4 or Azure resource-alias records. |
| `aaaa_records` | `{}` | Creates IPv6 or Azure resource-alias records. |
| `cname_records` | `{}` | Creates CNAME or supported resource-alias records. |
| `txt_records` | `{}` | Creates verification and policy text records. |
| `soa_record` | `null` | Overrides Azure's default SOA timings. |
| `role_assignments` | `{}` | Grants roles such as DNS Zone Contributor. |

## Cost considerations

Azure DNS charges for hosted zones and DNS query volume. Azure resource aliases
do not remove charges for their target services. DNS Resolver, Traffic Manager,
Front Door, and health monitoring are not created here and may add separate
costs.

## Security and operations

- Public records and TXT values are globally visible; never store credentials
  or private configuration in DNS.
- Scope automation identities to this zone with `DNS Zone Contributor` instead
  of subscription-wide rights.
- Use short TTLs before planned migrations and raise them after stability is
  confirmed.
- A CNAME cannot exist at the zone apex and cannot coexist with most other
  record types at the same name; validation rejects `@` CNAMEs.
- Customize SOA timers only when operators understand propagation and negative
  caching consequences.
- Protect registrar and parent-zone accounts with MFA and change controls.

## Outputs

The stack returns the zone ID and name, authoritative name servers, resource
group name, and managed record FQDNs grouped by record type.

## Destroy behavior

Destroy removes managed records, role assignments, and the zone. It also
removes the resource group when this stack created it, so do not place unrelated
resources there. Delegation at the registrar or parent zone is external and
remains until removed separately; remove it before destroying a production zone
to avoid dangling delegation.
