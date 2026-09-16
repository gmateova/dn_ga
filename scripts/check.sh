#!/usr/bin/env bash
set -euo pipefail

required=(terraform tflint checkov gitleaks conftest)
for cmd in "${required[@]}"; do
  command -v "${cmd}" >/dev/null 2>&1 || {
    echo "Missing required tool: ${cmd}" >&2
    exit 1
  }
done

echo "== terraform fmt =="
terraform fmt -check -recursive

echo "== terraform validate =="
while IFS= read -r -d '' dir; do
  echo "Validating ${dir}"
  terraform -chdir="${dir}" init -backend=false -input=false >/dev/null
  terraform -chdir="${dir}" validate
  rm -rf "${dir}/.terraform" "${dir}/.terraform.lock.hcl"
done < <(find tenants -name main.tf -printf '%h\0' | sort -zu)

echo "== tflint =="
tflint --recursive

echo "== checkov =="
checkov -d . --framework terraform --quiet

echo "== secret scan =="
gitleaks detect --source . --no-banner --redact

echo "All static quality/security checks passed."
