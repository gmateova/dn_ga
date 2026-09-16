# CI/CD model

## Pipeline inputs

Every deployment selects exactly one target:

```text
TENANT=customer-a
ENVIRONMENT=dev|preope|ope
```

`scripts/resolve-target.sh` rejects path traversal and unsupported environment names, then resolves the target to:

```text
tenants/<TENANT>/<ENVIRONMENT>
```

The same values derive a unique state key and GitLab resource lock. This prevents two applies for the same tenant/environment from running concurrently.

## Required protected/masked CI variables

Backend:

- `TF_HTTP_ADDRESS_BASE`
- `TF_HTTP_USERNAME`
- `TF_HTTP_PASSWORD`

OpenShift provider:

- `TF_VAR_openshift_api_url`
- `TF_VAR_openshift_token`
- `TF_VAR_openshift_ca_certificate`

Post-apply verification:

- `OPENSHIFT_API_URL`
- `OPENSHIFT_TOKEN`
- `OPENSHIFT_NAMESPACE`
- `POD_NAME`

Do not store these values in `.tfvars` files in Git.

## State isolation

A target `customer-a/dev` receives a state key like:

```text
customer-a/dev/terraform.tfstate
```

`customer-a/ope` receives a different state. Customer B receives a different state namespace again.

Backend credentials do not define ownership by themselves. The backend must additionally enforce authorization so an execution identity can access only the states it is allowed to manage.

## Promotion

The current PoC supports DEV, preOPE and OPE as explicit targets. Apply is manual and only available from the default branch.

For production use configure GitLab protected environments so OPE has stricter deployment permissions/approvals than DEV. Merge-request approval rules and protected branches should be configured in GitLab itself rather than encoded as pretend security in Terraform.

## Pipeline gates

Before apply:

1. Terraform formatting
2. Terraform validation
3. TFLint
4. Gitleaks secret scan
5. Checkov IaC scan
6. smoke validation
7. remote-state Terraform plan
8. OPA/Conftest policy evaluation
9. manual apply
10. post-apply OpenShift readiness check

A plan artifact expires after one day and the apply consumes that reviewed plan rather than silently creating a new plan.
