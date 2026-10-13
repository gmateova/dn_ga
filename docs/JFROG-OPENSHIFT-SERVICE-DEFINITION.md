# JFrog Artifactory – OpenShift Direct Integration
## Service Definition, Infrastructure Requirements and PCI DSS Review

**Status:** Proposed / subject to architecture, service-owner and PCI Security approval  
**Version:** 1.0 | **Date:** 2026-10-13  
**Consumer:** OpenShift Infrastructure / multi-customer platform  
**Provider:** JFrog Artifactory service owner (outside OpenShift team's operational responsibility)  
**Integration:** Direct OCI/Docker registry pulls from OpenShift worker nodes  
**Scope:** Multi-customer, multi-tenant, PCI and non-PCI environments

> This document defines **our requirements on the JFrog service**, not its internal implementation. It is not a PCI DSS certification or evidence of implemented controls. Actual PCI scope, isolation and compensating controls require Security/QSA review.

## 1. Service definition

| Attribute | Definition |
|---|---|
| Service | JFrog Artifactory OCI registry consumption |
| Purpose | Secure, reliable distribution of approved infrastructure and workload container images |
| Owner | JFrog service team (registry); OpenShift team (cluster integration) |
| Consumer | OpenShift worker nodes, cluster automation and authorized deployment workflows |
| Endpoint | JFrog-provided FQDN, TLS, Docker Registry HTTP API V2/OCI |
| Direction | OpenShift worker egress -> registry HTTPS/TCP 443 (unless approved endpoint specifies otherwise) |
| Authentication | Non-human scoped JFrog registry credentials in namespace-scoped imagePullSecrets |
| Authorization | Least privilege; separation by customer, environment, PCI boundary and role |
| Criticality | Critical for new pods requiring uncached images, upgrades, scaling and cluster recovery |
| SLA / SLO | To be agreed; do not assume 99.9% is an approved target |
| RTO / RPO | To be agreed with application/platform recovery objectives |
| Security scope | Security/PCI team to establish CDE and connected/security-impacting systems |
| Data handling | Images and metadata must not contain cardholder data, secrets or sensitive customer configuration; exceptions require formal review |

### In scope
Infrastructure-owned artifacts, direct image pull authentication, repository consumption, egress, certificate trust, monitoring, identity lifecycle, cross-tenant authorization, image retention and DR dependencies.

### Out of scope for OpenShift ownership
JFrog installation, storage implementation, Artifactory clustering, internal backup tooling, internal repository implementation and JFrog server-side administration. These remain provider responsibilities, but must satisfy the measurable requirements below.

## 2. Organizational boundary: dedicated Infrastructure JFrog Project

**REQ-ORG-01 (Must):** Provide a dedicated **JFrog Project** for Infrastructure, proposed key `infra`, with a documented project owner and delegated administration. This is the requested logical organizational level above individual repositories.

**REQ-ORG-02 (Must):** Support infrastructure-owned repositories within that Project, including production/nonproduction separation and independent write vs read permissions.

**REQ-ORG-03 (Must):** Prevent automatic cross-project access to private infrastructure artifacts; any sharing requires documented owner approval and narrowly scoped permissions.

**REQ-ORG-04 (Must):** Provide separate customer/tenant security boundaries where customer-specific artifacts or entitlements differ. A single `infra` Project is **not** sufficient proof of PCI or customer isolation.

**REQ-ORG-05 (Must):** Support additional JFrog Projects or repository-level permission targets where one Project cannot meet effective least-privilege or customer isolation requirements.

**REQ-ORG-06 (Should):** Support curated shared platform images that multiple authorized tenants may consume without duplicating identical binaries or granting access to private customer repositories.

Illustrative structure, subject to JFrog service-owner design:
```text
JFrog Platform
  Project infra
    infra-oci-nonprod-local
    infra-oci-prod-local
    infra-helm-local             # only if Helm packages are needed
    infra-oci-approved-remote    # optional, tightly controlled
    infra-oci-consumption-virtual # optional, effective permissions verified
  Customer-specific Projects / permissions
    ... when security boundaries require it
```
Names are examples, not mandated by PCI DSS. Projects are **logical access boundaries**, not separate infrastructure or guaranteed PCI segmentation. Distinguish shared infrastructure images from customer-owned application images; customer images need not be stored in the infra Project.

## 3. Identity, RBAC and secrets

**REQ-IAM-01 (Must):** Issue dedicated non-human read-only identities for OpenShift image pulls. No deploy, overwrite, delete, administrative or repository-management permissions.

**REQ-IAM-02 (Must):** Separate credentials between PCI and non-PCI, and production and nonproduction as our proposed security baseline. Separate customer identities wherever effective entitlements differ. A single identity may serve multiple namespaces **within the same approved trust boundary**.

**REQ-IAM-03 (Must):** Provide explicit effective repository permission mapping for every registry identity, including virtual/remote repository behavior, transitive access and cache/deploy permission implications.

**REQ-IAM-04 (Must):** Define credential issue, secure delivery, expiry, overlap during rotation, revocation, emergency replacement, access reviews and ownership. No static tokens in Git, Deployment manifests or CI logs.

**REQ-IAM-05 (Must):** Record and make available relevant authentication failures, authorization failures, permission changes, token lifecycle actions and privileged operations; align retention and integrity with PCI scope.

**REQ-IAM-06 (Should):** Support separate credentials per cluster or tenant to improve attribution and revocation, where operationally justified.

Kubernetes **ServiceAccounts are namespace-scoped**; JFrog registry identities are separate external identities. Each namespace needs its own Secret object even when it uses the same external identity. Reusing an external identity reduces JFrog-side attribution; require correlation with cluster logs where necessary.

Example:
```yaml
apiVersion: v1
kind: ServiceAccount
metadata:
  name: workload-sa
  namespace: customer-a-prod
imagePullSecrets:
  - name: jfrog-pull
```
The `jfrog-pull` Secret must be type `kubernetes.io/dockerconfigjson` in the same namespace. Prefer approved secret synchronization and automated rotation. Do not store credentials in the repository or distribute via cluster-global pull secret by default.

## 4. Network and TLS requirements

| ID | Requirement / acceptance evidence |
|---|---|
| NET-01 | Stable registry FQDN and documented API, OCI paths, redirects and endpoints |
| NET-02 | HTTPS from **every relevant OpenShift worker pool** (including DR/replacement nodes), not merely from pods or bastion |
| NET-03 | Valid TLS chain, hostname matching, approved CA; renewal and notice procedure |
| NET-04 | DNS/VIP, proxy/noProxy, egress IP, routing and firewall source/destination matrix |
| NET-05 | No unrestricted internet egress requirement for PCI node pools under proposed baseline |
| NET-06 | Documented handling of registry redirects, upstream dependencies and endpoint failover |
| NET-07 | Joint negative and positive connectivity tests from all relevant network zones |

Normal flow: **OpenShift worker node / CRI-O -> JFrog registry: TCP 443**. Additional flows for monitoring, token management or proxy require separate review. Image pull occurs on the node; Kubernetes pod NetworkPolicy alone does not constrain that traffic. No inbound connection from JFrog to OpenShift is required for standard direct pulls.

## 5. Artifacts, supply chain and release controls

| ID | Requirement |
|---|---|
| ART-01 | Production deployments reference approved immutable image digests, not only mutable tags |
| ART-02 | Restricted ability to overwrite/delete approved production artifacts |
| ART-03 | Defined build provenance, vulnerability scanning, exception handling and promotion approval |
| ART-04 | Repository retention must support rollback, node replacement and DR restore windows |
| ART-05 | No secrets, credentials, payment data or customer-sensitive configuration baked into images |
| ART-06 | Virtual/remote repositories must not expose restricted images or bypass approved upstream policies |
| ART-07 | Clear ownership for shared infrastructure images versus customer-specific application images |

These are **consumer acceptance requirements**. The JFrog team chooses the implementation and supplies test evidence.

## 6. Availability, capacity and operational service

| ID | Requirement / evidence |
|---|---|
| AVL-01 | Contracted SLA/SLO, measurement method and support hours |
| AVL-02 | Registry availability during planned/unplanned component failure and failover |
| AVL-03 | Capacity/load test for simultaneous pulls during worker upgrades, scaling and cluster restore |
| AVL-04 | Defined maintenance windows, advance notifications and change communication |
| AVL-05 | Health, error rate, latency, authentication failures and storage/replication monitoring |
| AVL-06 | Incident escalation, severity classification and on-call contacts |
| AVL-07 | Provider RTO/RPO and periodic restore validation |
| AVL-08 | Approved images remain retrievable despite external upstream outage where required |

**Impact:** Existing running containers normally continue through a registry outage. New pods needing an uncached image, rollout, node replacement and disaster recovery may fail with `ErrImagePull`/`ImagePullBackOff`. Node-local cache is not a dependable DR strategy.

## 7. Monitoring and operations

**OpenShift owns:** imagePullSecret lifecycle in namespaces; Kubernetes ServiceAccount linkage; worker egress, DNS and CA trust configuration; workload image references; consumer-side alerting on pull errors; deployment and restore tests; documented runbooks.

**JFrog owns:** registry availability and performance; FQDN/certificate; repository permissions and credentials issuance; registry logs and security events; backup/restore; repository lifecycle; service incident response.

**Joint:** capacity tests, negative-access tests, credential rotation tests, security review, incident exercises and end-to-end DR exercises.

Recommended consumer signals: `ErrImagePull`, `ImagePullBackOff`, 401/403, TLS validation failures, DNS failures, timeouts, token-expiry horizon and an authenticated test pull from an approved representative worker/network zone. A generic HTTPS health probe alone does not validate authorized image pulls.

## 8. PCI DSS 4.0.1 mapping (illustrative)

| Requirement family | Evidence expected |
|---|---|
| 1 – Network security | Registry/worker flows, segmentation rules and validated isolation |
| 2 – Secure configuration | Provider hardening baseline; OpenShift registry/CA policy |
| 5 and 6 – Malware / secure development | Approved artifact scanning, vulnerability management and controlled promotion |
| 7 – Access restrictions | Effective least-privilege permission matrix and access reviews |
| 8 – Identification and authentication | Non-human credential governance, appropriate MFA for interactive admin access |
| 10 – Logging | Access/privilege event collection, integrity, retention and review |
| 11 – Security testing | Cross-customer denial tests, segmentation/security testing as applicable |
| 12 – Governance | Documented service ownership, risk assessment, incident and third-party responsibilities |

A shared JFrog instance is not automatically prohibited by PCI DSS, but a Project/repository name alone does not prove compliant isolation. Confirm CDE scope and connected/security-impacting systems with Security/QSA.

## 9. Disaster recovery requirements

Provider must document and test: RTO, RPO, backup/restore of artifacts and metadata, registry endpoint recovery, token/authentication recovery, HA/DR failover, retention of production image digests, and response during external upstream outages.

**Joint DR acceptance:** restore or recreate a representative OpenShift worker and deploy a PCI-scoped application using its approved digest and least-privilege credentials during the agreed recovery scenario. Measure recovery time and collect evidence.

If direct pulls cannot satisfy availability/recovery requirements, record a design exception or reassess a replicated internal registry. This document assumes **direct** JFrog integration.

## 10. Production acceptance checklist

- [ ] Dedicated Infrastructure JFrog Project and ownership confirmed
- [ ] Infrastructure repository set and customer/PCI boundaries documented
- [ ] Registry endpoint, DNS, TLS and worker-node egress tested
- [ ] Registry identities issued with verified read-only permissions
- [ ] Namespace secrets and ServiceAccounts configured via approved automation
- [ ] Positive authenticated image pull from every required worker zone
- [ ] Negative tests: cross-customer, PCI/non-PCI and prod/nonprod denial
- [ ] Negative tests: pull identity cannot publish, overwrite, delete or administer
- [ ] Token rotation, expiry and revocation tested without uncontrolled outage
- [ ] Approved image digest and rollback retention demonstrated
- [ ] Parallel pull capacity and failure/failover tested
- [ ] Monitoring, logs, support ownership and escalation agreed
- [ ] RTO/RPO, restore and OpenShift end-to-end DR test accepted
- [ ] Security/PCI owner signs off on actual scope and controls

## 11. Open decisions / requested JFrog response

1. Confirm support for a dedicated `infra` JFrog Project and delegated Project Admin.
2. Confirm repository and identity isolation model for shared infra artifacts versus customer-specific artifacts.
3. Provide registry FQDN, network/TLS/proxy details and test endpoint.
4. Provide effective permission matrix and scoped read-only registry identities.
5. Provide token lifecycle, logging and operational contact process.
6. Provide SLA/SLO, capacity, maintenance notice, RTO/RPO and DR evidence.
7. Agree production acceptance tests and PCI Security/QSA review.

## 12. Ready-to-post review comment

> From the OpenShift Infrastructure perspective, we require a dedicated **Infrastructure JFrog Project** (proposed key `infra`) with infrastructure-owned OCI repositories and delegated Project Administration. JFrog is an external service dependency; its internal implementation and operation remain with the JFrog team. Our integration model is **direct OCI image pulls from OpenShift worker nodes**. We require a stable TLS-enabled endpoint, documented node egress, scoped non-human read-only pull identities, customer/PCI/environment isolation, credential rotation and revocation, controlled production image integrity/retention, auditable permissions and access, and agreed availability, incident, capacity and disaster-recovery objectives. One external JFrog pull identity may serve multiple OpenShift namespaces within the same approved security boundary, using separate namespace-local Secrets. Cross-customer and PCI/non-PCI access must be explicitly restricted and validated. Please confirm how the JFrog service will satisfy these requirements and provide evidence before production onboarding.

## 13. Reference documentation

- JFrog Projects: https://jfrog.com/help/r/jfrog-platform-administration-documentation/projects
- JFrog Artifactory repository types: https://jfrog.com/help/r/jfrog-artifactory-documentation/repository-management
- Kubernetes imagePullSecrets: https://kubernetes.io/docs/tasks/configure-pod-container/pull-image-private-registry/
- OpenShift documentation: https://docs.redhat.com/en/documentation/openshift_container_platform/
- PCI Security Standards Council: https://www.pcisecuritystandards.org/document_library/

**Validation note:** JFrog product edition/version, available Projects features, token capabilities, virtual/remote permissions and PCI scoping must be checked against the deployed product and the current service owner's configuration.
