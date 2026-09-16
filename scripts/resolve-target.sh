#!/usr/bin/env bash
set -euo pipefail

: "${TENANT:?TENANT is required}"
: "${ENVIRONMENT:?ENVIRONMENT is required}"

valid_component='^[a-z0-9][a-z0-9-]*$'

if [[ ! "${TENANT}" =~ ${valid_component} ]]; then
  echo "Invalid TENANT '${TENANT}'. Use lowercase letters, numbers and hyphens only." >&2
  exit 1
fi

if [[ ! "${ENVIRONMENT}" =~ ${valid_component} ]]; then
  echo "Invalid ENVIRONMENT '${ENVIRONMENT}'. Use lowercase letters, numbers and hyphens only." >&2
  exit 1
fi

case "${ENVIRONMENT}" in
  dev|test|prod) ;;
  *)
    echo "Unsupported ENVIRONMENT '${ENVIRONMENT}'. Allowed: dev, test, prod." >&2
    exit 1
    ;;
esac

TF_ROOT="tenants/${TENANT}/${ENVIRONMENT}"

if [[ ! -d "${TF_ROOT}" ]]; then
  echo "Terraform target does not exist: ${TF_ROOT}" >&2
  exit 1
fi

if [[ ! -f "${TF_ROOT}/main.tf" ]]; then
  echo "Terraform target is not deployable yet (main.tf missing): ${TF_ROOT}" >&2
  exit 1
fi

TF_STATE_KEY="${TENANT}/${ENVIRONMENT}/terraform.tfstate"
TF_PLAN_NAME="${TENANT}-${ENVIRONMENT}.tfplan"

export TF_ROOT TF_STATE_KEY TF_PLAN_NAME

if [[ -n "${CI_PROJECT_DIR:-}" ]]; then
  cat > "${CI_PROJECT_DIR}/target.env" <<EOF
TF_ROOT=${TF_ROOT}
TF_STATE_KEY=${TF_STATE_KEY}
TF_PLAN_NAME=${TF_PLAN_NAME}
DEPLOY_ENVIRONMENT=${TENANT}-${ENVIRONMENT}
EOF
fi

printf 'Target: %s\nState key: %s\nPlan: %s\n' "${TF_ROOT}" "${TF_STATE_KEY}" "${TF_PLAN_NAME}"
