# JFrog Consumption within OpenShift Container Service
## Service Definition, Integration Requirements and Offering GAP Assessment

**Document status:** DRAFT — pending service-owner, architecture, application and PCI Security validation  
**Document owner:** OpenShift Container Service / Infrastructure (Gabriela Mateova)  
**Date:** 2026-10-13  
**Scope:** Consumer-side definition and implementation of JFrog access from OpenShift; **not** the internal implementation design of the JFrog platform.  
**Integration model:** Direct connectivity from OpenShift worker nodes to the JFrog registry endpoint.  
**Related baseline:** Existing JFrog/OpenShift technical definition in separate PR #2. This document is independent and does not supersede it.

> **Evidence rule:** TBD means not yet confirmed. Do not infer that an undocumented JFrog capability is missing or implemented. PCI DSS compliance cannot be concluded from repository naming or RBAC configuration alone; Security/QSA must confirm scope and effectiveness of controls.

## 1. Purpose and expected outcome

JFrog is a prerequisite dependency for application installation and ongoing image consumption in the OpenShift Container Service offering. The objective is to define what the OpenShift service offers to tenants, the requirements it places on the upstream JFrog service, the ownership boundaries, and the gaps between requirements and the current offering.

**Required deliverables**
1. Approved OpenShift/JFrog service definition and RACI.
2. Validated direct connectivity design and operational integration.
3. Consolidated infrastructure and Smart MS application requirements.
4. Requirements-versus-offering assessment with evidence, gaps, owners and actions.
5. Security/PCI scope decision and operational acceptance sign-off.

## 2. Service offering and scope

**Service name:** Container Image Registry Consumption via JFrog  
**Parent service:** OpenShift Container Service  
**Service consumers:** OpenShift platform components; tenant workloads; Smart MS reference application; additional customers/tenants subject to onboarding.  
**Provider dependency:** JFrog Engineering-operated JFrog Artifactory service.

### In scope for OpenShift Infrastructure
- Define consumption patterns, onboarding prerequisites and namespace-level configuration.
- Validate direct image-pull connectivity from worker nodes and required DNS, certificates, routing and firewall paths.
- Integrate registry pull credentials through Kubernetes imagePullSecrets and workload ServiceAccounts or an approved cluster-level pull-secret mechanism.
- Define tenant isolation and PCI-relevant access requirements and request evidence from the JFrog owner.
- Document monitoring, incident escalation, operational handoffs, and testable acceptance criteria.
- Implement OpenShift-side configuration once approvals and credentials are available.

### Out of scope for OpenShift Infrastructure
- JFrog installation, clustering, storage, backup implementation, repository internals, global IAM or Xray configuration.
- JFrog-side account provisioning and permissions implementation (requested/validated by Infrastructure; executed by JFrog Engineering).
- Final PCI DSS compliance attestation or CDE scoping determination (Security/PCI owner).
- Application CI/CD changes owned by application teams, except for agreed integration guidance.

## 3. Confirmed coordination and working ownership

| Workstream | Lead / contact | Deliverable | Status |
|---|---|---|---|
| JFrog connectivity requirements | Johannes Roeske | Endpoint, ports, DNS, network dependencies | OPEN |
| Architecture update | Martin Kalata (Solution Design) | Approved direct-connect architecture diagram | OPEN |
| Firewall/network request | Michal Mesaros | Change/request and implementation | OPEN |
| JFrog support in OpenShift service; service definition | Gabriela Mateova | This document, integration acceptance, OpenShift-side implementation | IN PROGRESS |
| Application requirements | Smart MS / Martin Cipra; coordinated via Johannes | Representative application consumption requirements | TBD |
| Existing Nexus setup | Johannes Roeske | Baseline of existing repository and client consumption patterns | TBD |
| JFrog platform offering and evidence | JFrog Engineering | Service capabilities, access model, HA/DR, monitoring, audit evidence | TBD |
| PCI security acceptance | Security / PCI owner | Scope, segmentation and control sign-off | TBD |
| Professional Services involvement | Professional Services | Scope of engagement | TBD |

**RACI to validate:** OpenShift Infrastructure is responsible for OpenShift integration and service-consumer definition; JFrog Engineering is responsible for JFrog platform delivery; Network is responsible for network policy implementation; Solution Design is accountable for architecture approval **TBD**; Security owns PCI interpretation/acceptance **TBD**. Final RACI requires formal sign-off.

## 4. Required logical organization and tenancy

Infrastructure requires a **dedicated logical administrative boundary**, preferably a JFrog **Project** (e.g., `infra`) with its own repositories and role assignments, or an equivalent isolation mechanism documented by JFrog Engineering.

A JFrog Project is an organizational boundary above repositories; a separate JFrog instance is not inherently required. However, whether a shared instance is acceptable for PCI-related workloads depends on assessed segmentation, permissions, control-plane administration, auditability and Security approval.

### Requirements
- **INF-ORG-01:** Dedicated Infrastructure project or equivalent administrative boundary, with documented owners and delegated roles.
- **INF-ORG-02:** Infrastructure repositories separated from application/team repositories; names, formats and access rights agreed with JFrog owner.
- **INF-ORG-03:** Per-customer/tenant access separation; cross-tenant read, list, write and delete access denied by default.
- **INF-ORG-04:** Separate PCI and non-PCI security domains where Security determines this is necessary; no cross-domain sharing without explicit risk review.
- **INF-ORG-05:** Common/base images may be shared only via explicitly approved, read-only distribution paths with provenance and vulnerability controls.
- **INF-ORG-06:** Repository ownership and write/promotion rights remain explicit; no default broad anonymous or all-user access.
- **INF-ORG-07:** Define how a shared artifact may be consumed by multiple tenants without permitting unauthorized overwrites or exposing customer-private content.

**Repository naming convention:** TBD with JFrog Engineering. OpenShift Infrastructure specifies isolation and access outcomes, not the internal JFrog repository implementation.

## 5. Direct integration design

```text
[OpenShift namespace / Deployment / Pod]
             |
             | image reference and imagePullSecret
             v
[OpenShift worker node / kubelet / CRI-O]
             |
             | DNS lookup + TCP 443/TLS (subject to endpoint confirmation)
             | egress via approved network/firewall path
             v
[JFrog registry endpoint / approved ingress]
             |
             +--> [JFrog authorization and tenant-scoped repositories]
             +--> [JFrog audit / availability / security services]
```

**Important:** For normal image pulls, registry traffic originates from worker-node image-pull machinery, not necessarily from the application pod network. Pod NetworkPolicy alone is not sufficient evidence of node-to-registry egress control.

### Network flow matrix

| Source | Destination | Protocol / port | Purpose | Status |
|---|---|---|---|---|
| OpenShift worker-node egress addresses (cluster/environment: TBD) | JFrog registry FQDN: TBD | HTTPS TCP/443 assumed; confirm | Image pull, auth challenge/token exchange | TBD |
| OpenShift workers | DNS resolvers: TBD | DNS per platform design | Registry name resolution | TBD |
| OpenShift workers | JFrog auth endpoint if separate: TBD | HTTPS/port TBD | Registry authentication | TBD |
| OpenShift control-plane or automation nodes, only if needed | JFrog API endpoint: TBD | HTTPS/port TBD | Provisioning/health/API integration | TBD |
| CI/CD runners/build nodes (separate consumer scope) | JFrog endpoints: TBD | HTTPS/port TBD | Image push, artifact publication | TBD |

No inbound connection from JFrog into OpenShift is assumed for basic pulls. Proxy, TLS inspection, private routing, certificate chain, split-horizon DNS, HA endpoint and firewall source NAT must be confirmed with Network/JFrog owners. Explicit allowlisting is preferred over broad internet egress.

### OpenShift authentication
- Prefer a **JFrog read-only machine identity** scoped to the minimum repository/project paths needed by a specific security domain.
- One JFrog machine identity **can technically be reused across multiple namespaces** by creating a corresponding `kubernetes.io/dockerconfigjson` pull secret in each namespace and referencing it from workload ServiceAccounts; Kubernetes secrets themselves are namespace-scoped.
- Reuse **only** across namespaces with the same owner, trust boundary and required repository permissions. Avoid one organization-wide credential for unrelated customers or PCI/non-PCI domains.
- Document identity owner, credential lifetime, rotation, revocation, audit attribution, and whether short-lived or federated authentication is supported by JFrog (**TBD**).
- Avoid embedding passwords/tokens in image references, manifests, source control or unprotected CI logs.
- Namespace onboarding must configure pull secrets and service-account references, validate pulls, and test revoked/unauthorized access.

**Example, illustrative only:**
```yaml
apiVersion: v1
kind: ServiceAccount
metadata:
  name: application-runtime
  namespace: customer-a-app
imagePullSecrets:
  - name: jfrog-registry-pull
```

Credentials and Secret objects must be created separately via an approved secrets workflow; do not commit real values.

## 6. Security and PCI DSS requirements

The service must support a documented PCI DSS 4.0.1 control assessment, where applicable. The following are **consumer requirements**, not claims that PCI mandates specific JFrog product features.

| ID | Consumer requirement | Evidence / acceptance |
|---|---|---|
| SEC-01 | Security-approved CDE and connected-to-CDE scope and segmentation | Data-flow/scope diagram; Security approval; segmentation test plan |
| SEC-02 | Least privilege for humans and machine identities | Role matrix; effective-permission tests; periodic review |
| SEC-03 | Strong human authentication, MFA where applicable | SSO/MFA design and evidence from JFrog owner |
| SEC-04 | TLS certificate validation and protected secrets | Certificate trust and rotation; secret handling evidence |
| SEC-05 | Tenant and PCI-domain isolation | Negative cross-tenant/cross-domain pull, list, push and admin tests |
| SEC-06 | Auditable identity, configuration, access and privileged operations | Log field inventory; SIEM integration; retention and access evidence |
| SEC-07 | Approved artifact integrity, provenance and promotion | Immutable release/version controls, digest pinning/signature policy TBD |
| SEC-08 | Vulnerability and malicious artifact handling | Scanning/control process, severity policy and exception process TBD |
| SEC-09 | Incident response, credential revocation and recovery | Runbooks, escalation, tested revocation |
| SEC-10 | Patch/vulnerability ownership for registry dependency | JFrog service owner evidence and change process |

**PCI mapping for review:** PCI DSS requirements 1 (network security controls), 2 (secure configurations), 6 (secure software), 7 (access restriction), 8 (identity/authentication), 10 (logging), 11 (security testing), 12 (governance). Applicability, compensating controls and exact test procedures: **TBD with Security/QSA**.

## 7. Availability, operations and disaster recovery

JFrog is a prerequisite for installation, rollout, rescheduling onto nodes lacking cached images, and recovery. Running pods may continue during a registry outage, but recovery and scaling can fail; image caching must **not** be treated as an availability guarantee.

| Topic | Consumer requirement | Offered / target |
|---|---|---|
| Availability | Agreed availability target appropriate to OpenShift service criticality | TBD |
| Support hours | Escalation and coverage for incidents affecting deployments | TBD |
| Incident severity | Registry outage/failed pulls mapped to platform incident classification | TBD |
| Monitoring | Registry endpoint reachability, pull failures, latency, auth failures, expiry | TBD |
| Capacity | Pull throughput, concurrency, rate limits, storage/retention dependencies | TBD |
| Change management | Notice for planned downtime, API/endpoint/cert/auth changes | TBD |
| Backup | Provider-defined protected backup scope and restore ownership | TBD |
| RTO | Recovery time aligned with platform/application service requirements | TBD |
| RPO | Artifact and configuration recovery point target | TBD |
| DR validation | Evidence of restore/failover test and OpenShift image-pull retest | TBD |
| Artifact retention | Ensure required deployment and rollback image digests remain available | TBD |
| Fallback | Approved registry mirror/DR endpoint if required; avoid ungoverned public fallback | TBD |

**Minimum runbooks:** onboarding, pull-secret rotation, image-pull troubleshooting, JFrog outage escalation, certificate expiration, permission denial, tenant offboarding, DR endpoint transition.

## 8. Smart MS representative application requirements — TBD

Johannes to obtain requirements from the Smart MS application side (Martin Cipra as suggested contact). Confirm:

- Application/image inventory, registry formats and repositories: **TBD**
- Cluster(s), namespaces, customer/tenant separation and PCI relevance: **TBD**
- Pull-only vs CI push and release promotion responsibilities: **TBD**
- Required pull throughput, concurrent deployments, image sizes: **TBD**
- Availability, deployment windows, RTO/RPO and rollback expectations: **TBD**
- Required base images, third-party registries and proxy dependencies: **TBD**
- Credential ownership and secret rotation compatibility: **TBD**
- Image signing, scanning, provenance and retention: **TBD**
- Operational escalation and application acceptance test owner: **TBD**

Treat Smart MS as a representative application, not automatic proof that every tenant has identical requirements.

## 9. Requirements versus existing JFrog offering — GAP register

**Status legend:** TBD = no evidence yet; MEETS = tested/documented; PARTIAL = incomplete; GAP = confirmed shortfall; N/A = justified exclusion.

| ID | Requirement | JFrog offering/evidence | Status | Evidence owner | Action |
|---|---|---|---|---|---|
| GAP-01 | Dedicated Infrastructure project / equivalent | TBD | TBD | JFrog Engineering | Confirm organizational boundary and delegated administration |
| GAP-02 | Customer and tenant repository isolation | TBD | TBD | JFrog Engineering + Security | Demonstrate effective RBAC and negative tests |
| GAP-03 | PCI vs non-PCI isolation / scope | TBD | TBD | Security + JFrog Engineering | Scope decision, segmentation review |
| GAP-04 | Read-only machine identities and multi-namespace usage | TBD | TBD | JFrog Engineering | Confirm token/identity permissions, rotation and limits |
| GAP-05 | Direct worker-to-registry connectivity | TBD | TBD | Johannes / Network | FQDN, ports, source networks, firewall validation |
| GAP-06 | TLS trust and certificate lifecycle | TBD | TBD | JFrog Engineering + OpenShift | Confirm CA chain, trust distribution and renewal |
| GAP-07 | SSO/MFA and privileged administration | TBD | TBD | JFrog Engineering + Security | Supply IAM design and access review |
| GAP-08 | Audit events, SIEM and retention | TBD | TBD | JFrog Engineering + Security | Confirm logs, export, retention and test |
| GAP-09 | Artifact integrity, vulnerability scanning and promotion | TBD | TBD | JFrog Engineering + AppSec | Confirm controls and required policy |
| GAP-10 | HA, SLA, support and alerting | TBD | TBD | JFrog Service Owner | Provide offering and incident SLA |
| GAP-11 | Backup, RTO/RPO and DR exercise | TBD | TBD | JFrog Service Owner | Provide DR plan and test evidence |
| GAP-12 | Image retention and rollback | TBD | TBD | JFrog Engineering + Smart MS | Confirm immutable digests and retention |
| GAP-13 | Smart MS consumption and application acceptance | TBD | TBD | Johannes / Smart MS | Collect workload requirements and validate pull |
| GAP-14 | Current Nexus-to-JFrog migration impact | TBD | TBD | Johannes / JFrog Engineering | Compare Nexus groups/proxies, clients and access |
| GAP-15 | OpenShift onboarding/offboarding and runbooks | TBD | TBD | OpenShift Infrastructure | Document and test lifecycle |

A confirmed GAP must record impact, mitigation, accountable owner, target date, acceptance evidence and risk acceptance where needed. Do not mark an item MEETS without verifiable evidence.

## 10. OpenShift implementation plan (conditional)

1. Obtain endpoint, certificates, supported registry path, authentication and service owner details.
2. Confirm cluster/tenant/PCI scope and Security-approved credential boundary.
3. Obtain approved worker-node egress route and firewall change; update solution architecture.
4. Request least-privilege registry identity/identities from JFrog Engineering.
5. Create namespace-local imagePullSecrets through approved secret distribution; attach to designated ServiceAccounts.
6. Validate worker-node image pull from representative namespaces and node pools.
7. Execute negative tests for unauthorized repository and cross-tenant access.
8. Validate pull-secret rotation, token revocation, cert expiry handling and incident routing.
9. Exercise representative Smart MS deployment and rollback with pinned image digests.
10. Obtain JFrog, OpenShift, Network, Smart MS and Security sign-off before production onboarding.

**No production configuration changes are authorized by this document.**

## 11. Acceptance criteria / definition of done

- [ ] JFrog Service Offering and service owner confirmed.
- [ ] Final Service Definition and RACI approved.
- [ ] Smart MS requirements collected and signed off.
- [ ] Nexus baseline reviewed for migration/compatibility dependencies.
- [ ] Direct network flow matrix and architecture approved.
- [ ] Network/firewall change completed and validated from OpenShift worker nodes.
- [ ] Infrastructure logical boundary and repository access model demonstrated.
- [ ] Namespace pull authentication tested, including rotation and revocation.
- [ ] Tenant and PCI isolation requirements assessed and negative tests passed.
- [ ] Monitoring, alerting, incident support and change notification documented.
- [ ] SLA, RTO, RPO, backup/DR responsibilities and evidence reviewed.
- [ ] GAP register dispositioned; unresolved risks formally accepted or blocked.
- [ ] Representative Smart MS image pull/deployment/rollback verified.
- [ ] Final sign-offs recorded: OpenShift, JFrog, Solution Design, Network, Smart MS, Security.

## 12. Questions and evidence requests

### To Johannes Roeske
1. What are the final JFrog registry/auth/API endpoints, ports, DNS and connectivity prerequisites?
2. Can you provide current Nexus repository groups/proxies and consuming application patterns?
3. Can you coordinate Smart MS requirements with Martin Cipra?
4. Who provides the current JFrog Service Offering and evidence package?

### To JFrog Engineering / Service Owner
1. Is a dedicated Infrastructure JFrog Project supported, and which RBAC/project-admin boundaries are available?
2. What separation can be guaranteed for different customers and PCI/non-PCI domains?
3. Which machine-identity and token lifecycle options are supported?
4. What are the offered SLA, support hours, monitoring, SIEM/audit retention, HA, backup and DR targets?
5. What are the image retention, digest immutability, scanning and promotion controls?
6. What changes are required to support direct OpenShift pulls and negative-access tests?

### To Solution Design / Network
1. Confirm worker egress source ranges, route, proxies, firewall path, DNS, TLS and HA endpoints.
2. Update architecture and network-flow diagram and obtain approval.

### To Security / PCI owner
1. Which OpenShift workloads/tenants are in PCI scope or connected-to-CDE scope?
2. Is shared JFrog acceptable under tested logical isolation, or is a dedicated security boundary required?
3. What evidence, log retention and periodic control tests are mandatory?

### To Smart MS / Martin Cipra
1. Which image formats, namespaces, environments and customer boundaries are required?
2. Which deployment/rollback and availability expectations apply?
3. Who owns application-side registry references, pull-secret consumption and acceptance testing?

## 13. Proposed review comment (English)

> From the OpenShift Container Service perspective, JFrog is an upstream prerequisite for application installation and image pulls. We are defining our consumer-side service scope, direct worker-node connectivity, namespace-level authentication, tenant and PCI isolation requirements, operational support and DR dependencies. We request a dedicated Infrastructure logical boundary (preferably a JFrog Project) with appropriately scoped repositories and read-only machine identities. We do not prescribe JFrog's internal implementation; the JFrog service owner should confirm how the existing offering meets these requirements. We will consolidate Smart MS application requirements via Johannes and record each requirement as MEETS, PARTIAL, GAP or TBD against evidence. Until the service offering and security scope are confirmed, these are requirements and open validation items, not an assertion of compliance.

## 14. Change log

| Date | Version | Change |
|---|---|---|
| 2026-10-13 | 0.1 DRAFT | Independent Stuart-aligned service definition, responsibilities, direct integration and GAP register; unknowns explicitly TBD |
