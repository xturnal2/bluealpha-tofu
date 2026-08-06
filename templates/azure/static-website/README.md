# Azure static website

Hosts static content using Azure Storage static website hosting, with versioning,
soft delete, TLS 1.2, infrastructure encryption, and an optional Azure Front Door
Standard endpoint for global caching and delivery.

## Architecture

- one new or existing resource group;
- one StorageV2 account with the `$web` static website container;
- HTTPS-only transport, blob versioning, and blob/container soft delete;
- optional placeholder index and 404 documents;
- optionally, Azure Front Door Standard with compression, HTTPS redirects, and
  health probing.

Azure Storage static website content is anonymously readable through its web
endpoint by design. `allow_nested_items_to_be_public = false` prevents users
from independently enabling anonymous access on other containers. Front Door
does not make the storage web endpoint private.

## Prerequisites and authentication

- OpenTofu 1.8 or newer
- an Azure subscription and appropriate control-plane permissions
- Storage Blob Data Contributor when uploading content with Entra ID

```bash
az login
export ARM_SUBSCRIPTION_ID="00000000-0000-0000-0000-000000000000"
```

Use standard `ARM_*` environment variables for service-principal or workload
identity authentication. Do not place client secrets in `.tfvars`.

## Usage

```bash
cp example.tfvars terraform.tfvars
tofu init
tofu plan
tofu apply

az storage blob upload-batch \
  --account-name "$(tofu output -raw storage_account_name)" \
  --auth-mode login \
  --destination '$web' \
  --source ./dist \
  --overwrite
```

## Important flags

| Flag | Default | Impact |
|---|---:|---|
| `account_replication_type` | `"LRS"` | Lowest-cost local replication; ZRS/GRS/GZRS options improve resilience at added cost |
| `enable_versioning` | `true` | Retains prior blob versions and increases retained storage |
| `blob_delete_retention_days` | `7` | Sets the blob and container recovery window |
| `enable_cdn` | `false` | Adds Azure Front Door Standard base, request, and data-transfer charges |
| `enable_shared_access_key` | `true` | Preserves broad tooling compatibility; disable after verifying Entra-only deployment |
| `create_sample_content` | `true` | Creates placeholder index and 404 pages |

Storage redundancy support varies by region. Verify the selected replication
type in the target region before applying.

## Custom domains

The generated Front Door endpoint can be extended with
`azurerm_cdn_frontdoor_custom_domain`, DNS validation, and route association.
Those resources are excluded because domain ownership and DNS providers vary by
customer. Prefer Front Door for custom-domain HTTPS.

## Inputs

| Name | Type | Default | Description |
|---|---|---:|---|
| `subscription_id` | `string` | `null` | Azure subscription; null uses the environment |
| `project_name` | `string` | required | Project identifier |
| `environment` | `string` | `"dev"` | Environment identifier |
| `location` | `string` | `"eastus"` | Azure region |
| `create_resource_group` | `bool` | `true` | Create or reuse a resource group |
| `resource_group_name` | `string` | `null` | Explicit resource group name |
| `storage_account_name` | `string` | `null` | Globally unique account name |
| `account_replication_type` | `string` | `"LRS"` | Storage redundancy |
| `index_document` | `string` | `"index.html"` | Default document |
| `error_404_document` | `string` | `"404.html"` | Not-found document |
| `enable_versioning` | `bool` | `true` | Retain prior blob versions |
| `blob_delete_retention_days` | `number` | `7` | Soft-delete window |
| `enable_cdn` | `bool` | `false` | Add Azure Front Door Standard |
| `cdn_query_string_caching_behavior` | `string` | `"IgnoreQueryString"` | Front Door query-string cache behavior |
| `enable_shared_access_key` | `bool` | `true` | Permit account-key authentication |
| `create_sample_content` | `bool` | `true` | Create placeholder content |
| `tags` | `map(string)` | `{}` | Additional tags |

## Outputs

`resource_group_name`, `storage_account_name`, `storage_account_id`,
`storage_website_url`, `frontdoor_endpoint_url`, and `content_upload_command`.

## Cost, security, and destroy behavior

Storage capacity, operations, version retention, egress, and optional Front Door
are the primary costs. Use Azure Policy to add organization-specific diagnostic
settings and network requirements.

Before `tofu destroy`, preserve any site content you need. Deleting the storage
account removes the website and all blob versions. Soft delete does not protect
against storage-account deletion.
