output "zone_id" {
  description = "Route 53 hosted zone ID."
  value       = aws_route53_zone.this.zone_id
}

output "zone_arn" {
  description = "ARN of the hosted zone."
  value       = aws_route53_zone.this.arn
}

output "name_servers" {
  description = "Authoritative name servers for public delegation; empty for private zones."
  value       = aws_route53_zone.this.name_servers
}

output "primary_name_server" {
  description = "Primary Route 53 name server for the zone."
  value       = aws_route53_zone.this.primary_name_server
}

output "record_fqdns" {
  description = "FQDNs of records managed by this stack, keyed by input label."
  value = merge(
    { for key, record in aws_route53_record.standard : key => record.fqdn },
    { for key, record in aws_route53_record.alias : key => record.fqdn }
  )
}
