#!/usr/bin/env bash
set -euo pipefail

ROOT="tenants/example/dev"

cleanup() {
  rm -rf "${ROOT}/.terraform" "${ROOT}/.terraform.lock.hcl" /tmp/dn-ga-plan /tmp/dn-ga-plan.json
}
trap cleanup EXIT

export TF_VAR_openshift_api_url="https://127.0.0.1:6443"
export TF_VAR_openshift_token="smoke-test-placeholder-not-a-real-secret"
export TF_VAR_openshift_ca_certificate="-----BEGIN CERTIFICATE-----\nSMOKE-TEST-PLACEHOLDER\n-----END CERTIFICATE-----"

terraform -chdir="${ROOT}" init -backend=false -input=false
terraform -chdir="${ROOT}" validate

# A refresh-free plan checks the complete variable/module/resource graph without
# requiring a live OpenShift cluster in CI.
terraform -chdir="${ROOT}" plan \
  -refresh=false \
  -input=false \
  -lock=false \
  -var-file=terraform.tfvars.example \
  -out=/tmp/dn-ga-plan

terraform -chdir="${ROOT}" show -json /tmp/dn-ga-plan > /tmp/dn-ga-plan.json
conftest test /tmp/dn-ga-plan.json --policy policy

echo "Terraform smoke test and policy gate passed."
