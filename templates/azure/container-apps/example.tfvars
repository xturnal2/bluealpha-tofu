project_name = "acme-api"
environment  = "dev"
location     = "eastus"

container_image  = "mcr.microsoft.com/k8se/quickstart:latest"
container_port   = 80
container_cpu    = 0.5
container_memory = "1Gi"

min_replicas = 0
max_replicas = 3

enable_ingress           = true
external_ingress_enabled = false

environment_variables = {
  APP_ENV = "dev"
}

# Secret values are stored in OpenTofu state; use an encrypted remote backend.
secrets                      = {}
secret_environment_variables = {}

tags = {
  Owner      = "platform-team"
  CostCenter = "applications"
}
