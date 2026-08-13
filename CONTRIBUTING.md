# Contributing

Contributions that add providers, improve safety, or cover common customer
workloads are welcome.

## Local checks

Run these commands from the repository root:

```bash
tofu fmt -recursive -check
./scripts/validate.sh
```

On Windows:

```powershell
tofu fmt -recursive -check
./scripts/validate.ps1
```

Validation initializes each template and connected example without a backend and
does not create cloud resources.

## New-template checklist

Place a template at `templates/<cloud>/<stack>/` and include:

- `versions.tf` with an OpenTofu constraint and bounded provider constraints;
- `main.tf`, `variables.tf`, and `outputs.tf`;
- `README.md` with architecture, prerequisites, cost and security notes, usage,
  inputs, outputs, and destroy instructions;
- `example.tfvars` containing no credentials or customer identifiers;
- validation for constrained strings, CIDRs, mutually dependent flags, and
  numeric ranges;
- common project/environment tags or labels;
- no secrets in variables, outputs, examples, or committed state.

New flags should have a safe, unsurprising default. A flag that enables public
access or a material recurring charge must default to `false` and be called out
in the cost or security section.

## Connected-example checklist

Place a composition at `examples/<cloud>/<architecture>/`. Reuse published
templates through relative module sources, pass outputs directly into inputs,
and document application contracts, IAM, network flows, cost, operations, and
the protected destroy sequence. Include `versions.tf`, `main.tf`, `variables.tf`,
`outputs.tf`, `example.tfvars`, a provider lock file, and a README. Avoid remote
state dependencies and copied resource IDs.

## Pull requests

Keep a pull request focused on one stack or one cross-cutting improvement.
Include the OpenTofu version used for validation and, when possible, a redacted
plan summary. Do not commit `.terraform`, state, plan, or credential files.
