# AWS Route 53 hosted zone

Creates a public or VPC-associated private Route 53 hosted zone with optional
standard and AWS alias records. Public zones expose authoritative name servers
for registrar delegation; private zones require an explicit initial VPC
association.

## Architecture

- One public or private Route 53 hosted zone.
- One or more creation-time VPC associations for a private zone.
- Optional conventional DNS records with explicit TTLs.
- Optional `A` or `AAAA` alias records for AWS targets such as CloudFront,
  load balancers, and API Gateway.
- Conservative destroy behavior that refuses to delete unmanaged records.

Advanced routing policies, health checks, DNSSEC signing, Resolver endpoints,
query logging, and cross-account VPC association authorization are separate
operational concerns and are intentionally outside this foundational stack.

## Prerequisites and authentication

- OpenTofu 1.8 or newer.
- AWS credentials allowed to manage Route 53 zones, records, and tags.
- For a public zone, control of the parent DNS zone or registrar so the returned
  name servers can be delegated.
- For a private zone, at least one VPC ID in the same partition and permission
  to associate it.

## Usage

```bash
cp example.tfvars terraform.tfvars
tofu init
tofu plan
tofu apply
```

After creating a public zone, copy `name_servers` into the parent zone's NS
record or the domain registrar. The zone is not authoritative to clients until
that delegation propagates.

## Important inputs

| Input | Default | Purpose |
|---|---:|---|
| `zone_name` | required | Fully qualified DNS suffix managed by the zone. |
| `private_zone` | `false` | Switches from public DNS to VPC-only resolution. |
| `vpc_associations` | `{}` | Supplies initial private-zone VPCs and regions. |
| `records` | `{}` | Creates conventional records with TTL and value sets. |
| `alias_records` | `{}` | Creates AWS alias records without a TTL. |
| `delegation_set_id` | `null` | Reuses a public-zone delegation set. |
| `force_destroy` | `false` | Allows deletion even when unmanaged records remain. |

## Cost considerations

Route 53 charges for hosted zones, queries, health checks, Resolver features,
and some advanced routing capabilities. Alias queries to selected AWS targets
may be priced differently. Private zones are charged per associated zone and
query volume. This template creates no health checks or Resolver endpoints.

## Security and operations

- Public DNS records are globally visible; never publish secrets in TXT or
  other records.
- A private zone is reachable only through associated networks, but workloads
  still need appropriate VPC DNS settings and network paths.
- Use low TTLs before migrations and restore normal TTLs after stability is
  confirmed.
- `allow_overwrite` defaults to false to avoid silently adopting or replacing a
  record created by another owner.
- Keep registrar access protected with MFA and registry lock where available.
- Enable DNSSEC and query logging through a reviewed organization design when
  required; both introduce additional keys, policies, and log destinations.

## Outputs

The stack returns the zone ID and ARN, public name-server delegation values,
the primary name server, and FQDNs for records managed here.

## Destroy behavior

Managed records are deleted before the zone. With `force_destroy = false`, AWS
refuses to remove a zone containing additional records, protecting entries
managed by other systems. Setting `force_destroy = true` deletes those records
too; review the complete zone contents and delegation before enabling it. Parent
registrar or DNS delegation is external and is not removed automatically.
