# Security policy

## Reporting a vulnerability

Please do not open a public issue for a suspected vulnerability. Report it
privately through GitHub's **Security advisories** page for this repository.
Include the affected template, a reproduction or plan excerpt, impact, and any
suggested mitigation.

## Consumer responsibilities

Templates provide secure defaults, but consumers remain responsible for:

- reviewing the plan and provider release notes;
- restricting cloud credentials and CI identities to least privilege;
- selecting encryption, retention, logging, and network controls appropriate
  for their data;
- monitoring deployed resources and provider security advisories;
- keeping state in an encrypted, access-controlled remote backend.

Never commit OpenTofu state, plan files, credentials, or populated variable
files containing sensitive values.
