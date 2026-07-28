# AWS static website

Hosts static content in a private, encrypted S3 bucket and delivers it through
CloudFront over HTTPS. CloudFront Origin Access Control is the only principal
allowed to read site objects; S3 public access remains fully blocked.

## Architecture

- private S3 origin with ownership enforcement, AES-256 encryption, versioning,
  and configurable noncurrent-version expiration;
- CloudFront distribution with IPv6, HTTP/2 and HTTP/3, compression, HTTPS
  redirects, configurable caching, and browser security headers;
- optional custom domain certificate, aliases, AWS WAF web ACL, SPA routing
  fallback, and standard access logging;
- optional dedicated S3 log bucket with encryption and automatic expiration.

This stack creates infrastructure, not an application build pipeline.

## Prerequisites and authentication

- OpenTofu 1.8 or newer
- an AWS account with permission to manage S3, CloudFront, and the optional
  logging resources
- AWS credentials supplied through the standard environment, shared
  credentials file, AWS IAM Identity Center, or a workload identity

When access logging is enabled, the deployer also needs `s3:GetBucketAcl` and
`s3:PutBucketAcl` on the log bucket so CloudFront can add its log-delivery ACL.
The log bucket defaults to `us-east-1` because CloudFront standard logging does
not support S3 buckets in every AWS region. If changing `log_bucket_region`,
confirm the destination region is supported by CloudFront standard logging.
Do not place AWS access keys in `.tfvars`.

## Usage

```bash
cp example.tfvars terraform.tfvars
tofu init
tofu plan
tofu apply
tofu output -raw website_url
```

Upload a built site and invalidate CloudFront:

```bash
aws s3 sync ./dist "s3://$(tofu output -raw bucket_name)/" --delete
aws cloudfront create-invalidation \
  --distribution-id "$(tofu output -raw cloudfront_distribution_id)" \
  --paths "/*"
```

CloudFront deployment commonly takes several minutes.

## Important flags

| Flag | Default | Impact |
|---|---:|---|
| `enable_versioning` | `true` | Retains replaced objects for recovery and adds storage usage |
| `noncurrent_version_expiration_days` | `30` | Bounds old-version storage; zero retains versions indefinitely |
| `enable_access_logging` | `false` | Creates a log bucket and adds S3 request/storage costs |
| `log_bucket_region` | `"us-east-1"` | Selects a supported S3 region for CloudFront logs |
| `log_retention_days` | `90` | Controls automatic access-log expiration |
| `enable_spa_fallback` | `false` | Maps origin 403/404 responses to the index with status 200 |
| `forward_query_strings` | `false` | Adds all query strings to the cache key and origin request |
| `price_class` | `"PriceClass_100"` | Trades edge coverage for CloudFront delivery cost |
| `create_sample_content` | `true` | Creates a placeholder index page |
| `force_destroy` | `false` | Protects non-empty buckets from destroy |

`PriceClass_100` uses the smallest edge-location set.
`PriceClass_All` provides the broadest coverage. Choose based on audience
location and measured performance rather than assuming broader is always
necessary.

## Custom domains and WAF

Set `aliases` and `acm_certificate_arn` together. CloudFront requires its ACM
certificate in `us-east-1`, even when the S3 origin is elsewhere. After apply,
create a Route 53 alias or equivalent DNS record using
`cloudfront_domain_name` and `cloudfront_hosted_zone_id`.

DNS and certificate creation are intentionally outside this stack because
domain ownership and DNS providers vary. Set `web_acl_id` to a CloudFront-scope
AWS WAFv2 web ACL ARN when edge filtering is required.

## Caching and SPA behavior

The default cache policy excludes cookies, headers, and query strings and
enables Brotli/Gzip cache variants. Adjust the min/default/max TTL variables to
match your deployment frequency. Run an invalidation after releases that reuse
object names.

`enable_spa_fallback` is useful for client-side routers but makes genuine missing
objects return HTTP 200. Leave it disabled for documentation and conventional
sites where accurate 404 status codes matter.

## Inputs

| Name | Type | Default | Description |
|---|---|---:|---|
| `project_name` | `string` | required | Project identifier |
| `environment` | `string` | `"dev"` | Environment identifier |
| `aws_region` | `string` | `"us-east-1"` | S3 bucket region |
| `site_bucket_name` | `string` | `null` | Explicit globally unique origin bucket name |
| `index_document` | `string` | `"index.html"` | Default root object |
| `aliases` | `list(string)` | `[]` | CloudFront custom domain names |
| `acm_certificate_arn` | `string` | `null` | ACM certificate for custom aliases |
| `web_acl_id` | `string` | `null` | Optional CloudFront-scope WAFv2 ARN |
| `price_class` | `string` | `"PriceClass_100"` | CloudFront edge coverage |
| `enable_ipv6` | `bool` | `true` | Enable CloudFront IPv6 |
| `enable_versioning` | `bool` | `true` | Retain object versions |
| `noncurrent_version_expiration_days` | `number` | `30` | Old-version retention; zero disables expiration |
| `enable_access_logging` | `bool` | `false` | Store CloudFront request logs |
| `log_bucket_name` | `string` | `null` | Explicit globally unique log bucket name |
| `log_bucket_region` | `string` | `"us-east-1"` | Access-log bucket region |
| `log_retention_days` | `number` | `90` | Access-log retention |
| `enable_spa_fallback` | `bool` | `false` | Serve the index for 403/404 responses |
| `forward_query_strings` | `bool` | `false` | Include all query strings in cache keys |
| `cache_min_ttl_seconds` | `number` | `0` | Minimum cache lifetime |
| `cache_default_ttl_seconds` | `number` | `3600` | Default cache lifetime |
| `cache_max_ttl_seconds` | `number` | `31536000` | Maximum cache lifetime |
| `create_sample_content` | `bool` | `true` | Create a placeholder page |
| `force_destroy` | `bool` | `false` | Delete non-empty buckets on destroy |
| `tags` | `map(string)` | `{}` | Additional tags |

## Outputs

`bucket_name`, `bucket_arn`, `cloudfront_distribution_id`,
`cloudfront_distribution_arn`, `cloudfront_domain_name`,
`cloudfront_hosted_zone_id`, `website_url`, `access_log_bucket_name`,
`content_upload_command`, and `cache_invalidation_command`.

## Cost, security, and destroy behavior

Primary costs are CloudFront data transfer/requests, S3 storage/requests, access
logs, WAF when supplied, and retained object versions. S3 remains private, the
bucket policy denies insecure transport, and CloudFront adds HSTS without
subdomain inheritance,
`X-Content-Type-Options`, frame denial, referrer, and XSS-protection headers.
Add a content security policy in the application or a site-specific response
headers policy after testing required scripts and origins.

With `force_destroy = false`, externally uploaded content and logs prevent
bucket deletion. Empty the buckets, including object versions, before
`tofu destroy`, or deliberately enable `force_destroy` after reviewing the
data-loss impact.
