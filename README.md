# DN Global Automation Standard - PoC

This repository is a starting implementation of the Diebold Nixdorf Global Automation Standard.

The design follows these principles:

- code is the source of truth
- desired state is declared and versioned
- state is explicit and owned
- tenant and environment boundaries are explicit
- drift must be detectable
- secrets must never be stored in Git
- production changes pass review, automated quality/security gates and an explicit apply step
- automation should be idempotent

## Scope of this PoC

1. One-time GitLab installation on Oracle Linux 9.
2. Terraform/OpenTofu repository layout for multiple tenants and multiple environments.
3. Reusable Terraform module for provisioning an OpenShift Pod.
4. Static checks, secret scanning, Terraform validation, policy checks and smoke tests.
5. GitLab CI/CD pipeline with validate -> security -> test -> plan -> apply stages.

## Repository layout

```text
.
├── bootstrap/
│   └── gitlab-oel9/
│       ├── install.sh
│       └── gitlab.rb.example
├── modules/
│   └── openshift-pod/
│       ├── main.tf
│       ├── variables.tf
│       └── outputs.tf
├── tenants/
│   └── example/
│       ├── dev/
│       ├── test/
│       └── prod/
├── policy/
│   └── terraform.rego
├── scripts/
│   ├── check.sh
│   └── smoke.sh
├── .gitlab-ci.yml
├── .gitignore
├── .tflint.hcl
└── README.md
```

## Multi-tenant / multi-environment Terraform model

Reusable infrastructure belongs in `modules/`. Live desired state belongs under `tenants/<tenant>/<environment>/`.

Each tenant/environment is a separate Terraform root module and **must use a separate backend/state**. Never share one state between customers or between DEV/TEST/PROD.

Example:

```text
tenants/
├── customer-a/
│   ├── dev/
│   ├── test/
│   └── prod/
└── customer-b/
    ├── dev/
    ├── test/
    └── prod/
```

The example roots deliberately contain placeholder OpenShift values. Copy the example tenant and provide real cluster/namespace/image/resource values later.

## Secrets

Provider tokens, OpenShift credentials, GitLab root password, registry credentials and other secrets are not Terraform variables committed to Git. Supply them from GitLab protected/masked CI/CD variables or the enterprise secrets platform.

The pipeline includes secret detection as a mandatory quality gate.

## GitLab bootstrap

`bootstrap/gitlab-oel9/install.sh` is intended for a one-time GitLab installation on a dedicated OEL9 VM. It is safe to rerun: it checks installed state and reconciles the GitLab configuration instead of blindly reinstalling.

Run as root after supplying the required environment values:

```bash
export GITLAB_EXTERNAL_URL='https://gitlab.example.internal'
export GITLAB_INITIAL_ROOT_PASSWORD='use-a-secret-source'
sudo -E ./bootstrap/gitlab-oel9/install.sh
```

The script intentionally does not hard-code DN proxy, SMTP, LDAP, certificate or package repository values. Those inputs will be added when the real environment values are available.

## Terraform example

```bash
cd tenants/example/dev
terraform init -backend=false
terraform validate
terraform plan -var-file=terraform.tfvars.example
```

The provider is configured from environment variables/CI secrets. No OpenShift token is stored in the repository.

## Quality gates

Run locally:

```bash
./scripts/check.sh
./scripts/smoke.sh
```

The CI pipeline runs formatting, Terraform validation, TFLint, Checkov, secret scanning, OPA/Conftest policy checks and smoke tests before a plan can be produced.

`apply` is intentionally manual and restricted to protected branches/environments. PROD additionally requires the agreed DN approval controls.

## Environment model

The Global Automation standard uses exactly three deployment environments:

- `dev` - development and early integration
- `test` - controlled validation before production
- `prod` - production, protected and approval-gated

The environment name is part of the Terraform state ownership boundary, for example `customer-a/dev/terraform.tfstate`, `customer-a/test/terraform.tfstate`, and `customer-a/prod/terraform.tfstate`.

## Next inputs

The code is structured so these values can be supplied without redesigning the repository:

- tenant names
- OpenShift API/provider authentication model
- namespace/project names
- container image/registry
- CPU/memory requests and limits
- labels/annotations
- service account
- GitLab FQDN, certificate, proxy, SMTP and LDAP settings
- remote Terraform backend
- policy thresholds and required approvals
