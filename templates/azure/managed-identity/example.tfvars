subscription_id = "00000000-0000-0000-0000-000000000000"
location        = "eastus"
project_name    = "example-api"
environment     = "dev"

# Example GitHub Actions OIDC trust. Pin the subject to the repository and branch
# or environment that is actually authorized to assume this identity.
federated_credentials = {
  github_main = {
    issuer  = "https://token.actions.githubusercontent.com"
    subject = "repo:example/example-api:ref:refs/heads/main"
  }
}

# Add least-privilege target scopes and roles after the target resources exist.
role_assignments = {}

tags = {
  Owner      = "platform-team"
  CostCenter = "shared-services"
}
