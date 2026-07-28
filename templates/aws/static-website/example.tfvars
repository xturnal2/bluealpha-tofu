project_name = "acme-docs"
environment  = "dev"
aws_region   = "us-east-1"

# Deterministic, globally unique names are generated when these remain null.
site_bucket_name  = null
log_bucket_name   = null
log_bucket_region = "us-east-1"

enable_versioning                  = true
noncurrent_version_expiration_days = 30
enable_access_logging              = false
enable_spa_fallback                = false
forward_query_strings              = false
create_sample_content              = true
price_class                        = "PriceClass_100"

# For a custom domain, provide both values and create the DNS alias separately.
# aliases             = ["docs.example.com"]
# acm_certificate_arn = "arn:aws:acm:us-east-1:123456789012:certificate/..."

tags = {
  Owner      = "web-team"
  CostCenter = "marketing"
}
