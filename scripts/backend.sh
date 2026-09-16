#!/usr/bin/env bash
set -euo pipefail

: "${TF_ROOT:?TF_ROOT is required}"
: "${TF_STATE_KEY:?TF_STATE_KEY is required}"
: "${TF_HTTP_ADDRESS_BASE:?TF_HTTP_ADDRESS_BASE is required}"

base="${TF_HTTP_ADDRESS_BASE%/}"
address="${base}/${TF_STATE_KEY}"

args=(
  "-backend-config=address=${address}"
  "-backend-config=lock_address=${address}/lock"
  "-backend-config=unlock_address=${address}/lock"
  "-backend-config=lock_method=POST"
  "-backend-config=unlock_method=DELETE"
  "-backend-config=retry_wait_min=5"
)

# Authentication is intentionally supplied by protected/masked CI variables.
[[ -n "${TF_HTTP_USERNAME:-}" ]] && args+=("-backend-config=username=${TF_HTTP_USERNAME}")
[[ -n "${TF_HTTP_PASSWORD:-}" ]] && args+=("-backend-config=password=${TF_HTTP_PASSWORD}")

terraform -chdir="${TF_ROOT}" init -input=false -reconfigure "${args[@]}"
