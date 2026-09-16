# State and tenancy standard

## Rule 1 - one state per tenant/environment

Never put multiple customers or multiple lifecycle environments into one Terraform state.

```text
customer-a/dev     -> state A
customer-a/preope  -> state B
customer-a/ope     -> state C
customer-b/dev     -> state D
```

This limits blast radius, makes ownership explicit and permits separate execution identities and approval controls.

## Rule 2 - reusable modules contain no tenant secrets

`modules/` contains implementation only. Tenant-specific desired state is declared in `tenants/<tenant>/<environment>/` and secrets are injected at runtime.

## Rule 3 - state is remote and locked

Local state is not a production backend. CI initializes an HTTP-compatible remote backend with locking. The backend URL is derived from the tenant/environment state key.

## Rule 4 - credentials are scoped

The long-term model is one scoped execution identity per tenant/environment or the smallest practical security boundary. OPE credentials must not be available to DEV jobs.

## Rule 5 - import is deliberate

Existing resources are not silently adopted. If an existing resource must become Terraform-managed, create the matching configuration, review it, import the resource into the correct tenant/environment state, and verify a no-surprise plan before normal lifecycle management begins.

## Rule 6 - destructive changes require policy

The PoC starts with code/security checks. Before production rollout, add policy rules for destructive changes and the final DN resource standards. OPE applies remain manual and protected.
