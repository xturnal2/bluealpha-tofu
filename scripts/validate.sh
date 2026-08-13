#!/usr/bin/env bash
set -euo pipefail

repo_root="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"

while IFS= read -r versions_file; do
  template_dir="$(dirname "$versions_file")"
  echo "Validating ${template_dir#"$repo_root/"}"
  tofu -chdir="$template_dir" init -backend=false -input=false
  tofu -chdir="$template_dir" validate
done < <(find "$repo_root/templates" "$repo_root/examples" -name versions.tf -type f | sort)
