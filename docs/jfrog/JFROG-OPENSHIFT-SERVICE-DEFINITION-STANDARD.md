# Service Definition — JFrog Container Registry Integration for OpenShift Container Service

**Document status:** Proposed service standard — approval pending  
**Date:** 2026-10-13  
**Owner:** OpenShift Infrastructure / Container Platform Team  
**Service dependency owner:** Central JFrog Artifactory Service Team  
**Integration model:** Direct OCI container image pulls from OpenShift worker nodes  
**Applicability:** Enterprise multi-customer, multi-tenant, PCI-scoped and non-PCI OpenShift workloads

> This is the OpenShift team's **required service standard**, not a description of what the current JFrog offering already delivers. Unverified service-specific values are marked **TBD**. The JFrog team is responsible for how it implements the required outcomes. Security/QSA must confirm PCI scope and applicable controls.

## 1. Service description

The **JFrog Container Registry Integration Service** provides secure, controlled and reliable access to approved container images hosted on the centrally managed JFrog Artifactory platform for workloads running on the enterprise OpenShift Container Service.

The service enables authorized OpenShift workloads across multiple namespaces, tenants, customers and environments to retrieve OCI/Docker container images directly from JFrog Artifactory through authenticated registry access. The integration supports enterprise multi-tenancy, least privilege, workload isolation, secure software delivery, PCI DSS requirements where applicable, and standardized application deployment.

JFrog remains an externally managed dependency. OpenShift Infrastructure owns cluster-side connectivity and configuration, namespace credential distribution, integration validation, consumer monitoring and escalation. The JFrog Service Team owns registry endpoints, platform security and availability, repository provisioning and permissions, artifact storage and retention, backup, recovery and registry-side incidents.

### Customer-facing service capabilities
1. Onboard an approved namespace/workload to consume authorized JFrog OCI images.
2. Provide an approved registry access method through a non-human, read-only machine identity.
3. Bind namespace-scoped image pull credentials to a designated Kubernetes ServiceAccount.
4. Restrict image access by customer, tenant, environment and PCI security boundary.
5. Provide standard procedures for onboarding, rotation, revocation, incident response and offboarding.
6. Validate real image pulls, rescheduling and rollback for representative workloads.
7. Monitor registry consumption failures and route incidents to the correct provider.

### Exclusions
The OpenShift service does not install, patch, operate, back up or internally configure the JFrog platform; it does not own application CI image publishing or the final PCI compliance attestation.

## 2. Service parameters and ownership

| Attribute | Definition |
|---|---|
| Parent service | OpenShift Container Service |
| Integration | Direct worker-node -> JFrog registry |
| Consumer | OpenShift cluster runtime, infrastructure workloads and authorized application tenants |
| Image protocol | OCI/Docker Registry API over HTTPS |
| Registry FQDN and auth endpoints | TBD — JFrog provider |
| Availability / SLA | TBD — agree against OpenShift workload criticality |
| Support hours / escalation | TBD — JFrog service owner |
| Recovery objectives (RTO/RPO) | TBD — align with platform/application recovery |
| Security boundary | Per customer/tenant, environment and PCI scope, subject to Security assessment |
| Data classification | Approved images and metadata; secrets/payment data must not be embedded |
| Production enablement | Requires network, IAM, security and operational acceptance |

## 3. Required logical allocation of repositories

**ORG-01 (MUST):** Infrastructure-owned images must have a clearly identifiable, access-controlled repository allocation within JFrog, with named ownership and delegated permissions.

**ORG-02 (MUST):** Infrastructure publication and consumption permissions must be independent of unrelated application teams. No default cross-customer access to private artifacts.

**ORG-03 (MUST):** Separate effective permissions for production vs nonproduction and PCI vs non-PCI domains as required by approved security policy.

**ORG-04 (MUST):** Support common approved base/platform images shared read-only across authorized tenants without exposing tenant-private repositories.

**ORG-05 (MUST):** Repository lifecycle, retention, immutable production digests and authorized promotion/publishing must be documented.

**ORG-06 (SHOULD):** Delegated infrastructure repository administration without platform-wide JFrog administrator privileges.

**Implementation-neutral requirement:** A **new JFrog Project is not mandatory**. Existing `systems` or another organizational allocation may be used if JFrog demonstrates the necessary ownership, access restrictions and auditability. A dedicated Project is an option if existing boundaries cannot meet requirements. Repository names and JFrog internal design remain provider decisions.

## 4. Network and TLS requirements

| ID | Mandatory OpenShift requirement | Acceptance evidence |
|---|---|---|
| NET-01 | Stable DNS-resolvable registry endpoint from every relevant worker pool, including replacement/DR nodes | Worker-node DNS and real image pull |
| NET-02 | Registry and auth endpoints over approved TLS (TLS 1.2+; TLS 1.3 preferred) with valid hostnames and CA chain | Certificate and trust verification |
| NET-03 | Explicit approved worker-node outbound firewall connectivity; no default inbound registry-to-cluster flow | Source/destination/port matrix and firewall change |
| NET-04 | All redirects, token/auth services and image-layer endpoints reachable, including proxy/noProxy considerations | End-to-end pull test |
| NET-05 | Resilient DNS, ingress and registry failover paths appropriate to production criticality | Documented failover and validation |
| NET-06 | Connectivity from all applicable network/PCI zones without unrestricted public internet egress | Network/security approval |
| NET-07 | Concurrent image pull capacity for node replacement, upgrades and scale-out | Capacity acceptance test |

### Required network flows

| Source | Destination | Protocol / port | Purpose |
|---|---|---|---|
| OpenShift worker-node egress IPs / NAT: **TBD** | JFrog registry FQDN: **TBD** | HTTPS / TCP 443 preferred, confirm | OCI manifests and image layers |
| OpenShift worker-node egress IPs / NAT: **TBD** | JFrog auth/token endpoint: **TBD** | HTTPS / port TBD | Registry authentication |
| OpenShift worker nodes | Approved enterprise DNS | DNS per enterprise network standard | Resolve registry/auth FQDN |
| CI/CD builders/runners, if required | JFrog publish endpoint: **TBD** | HTTPS / port TBD | Separate image publishing flow, outside runtime pull scope |

**Technical note:** kubelet/CRI-O pulls images on the worker node. Pod NetworkPolicy does not, by itself, secure the node-to-registry pull path. Network/firewall rules must reflect actual worker egress/NAT addresses. No JFrog-initiated inbound connection to OpenShift is required for standard direct pulls.

## 5. Authentication, authorization and ServiceAccounts

| ID | Mandatory requirement |
|---|---|
| IAM-01 | Use dedicated non-human JFrog identities; never personal user credentials for runtime pulls |
| IAM-02 | Runtime pull identity has only effective read/pull rights to authorized OCI paths; no push, overwrite, delete or admin |
| IAM-03 | Separate machine identities by customer/security boundary when permissions differ; separate PCI/non-PCI and production/nonproduction by default |
| IAM-04 | One JFrog identity may be reused by multiple namespaces only within the same approved trust boundary |
| IAM-05 | Each namespace stores its own `kubernetes.io/dockerconfigjson` Secret, bound to its own Kubernetes ServiceAccount |
| IAM-06 | Token creation, expiration, rotation with overlap, revocation, ownership and emergency replacement must be defined |
| IAM-07 | Registry credentials never stored in Git, image layers, deployment YAML or unprotected logs |
| IAM-08 | Human administration and image publication must use distinct authorization paths from runtime image pulls |
| IAM-09 | Effective permissions must be validated through positive and negative pull tests, including virtual/remote repository behavior |

**Default OpenShift pattern:** namespace-local imagePullSecrets linked to a designated ServiceAccount, not a cluster-global shared pull credential across unrelated tenants.

```yaml
apiVersion: v1
kind: ServiceAccount
metadata:
  name: application-runtime
  namespace: customer-a-prod
imagePullSecrets:
  - name: jfrog-registry-pull
```

The `jfrog-registry-pull` Secret is created in the same namespace via approved secrets management; it is **not** stored in source control. The workload references `serviceAccountName: application-runtime`. A Kubernetes ServiceAccount itself cannot span namespaces; a JFrog machine identity can technically be reused across multiple namespace-local Secrets where approved.

## 6. PCI DSS and multi-tenant security

These are our **security outcomes**, not claims that PCI DSS prescribes a specific JFrog product topology.

| ID | Required control outcome | Test/evidence |
|---|---|---|
| SEC-01 | Tenant A identity cannot read/list/push/delete Tenant B private images | Negative cross-tenant tests |
| SEC-02 | PCI and non-PCI image access separated according to assessed security boundaries | PCI scope and permission matrix |
| SEC-03 | No anonymous access to restricted production artifacts | Unauthorized access tests |
| SEC-04 | Encryption in transit and protected machine credentials | TLS and secret lifecycle evidence |
| SEC-05 | Auditable authentication, permission changes and privileged operations | Log/SIEM and retention evidence |
| SEC-06 | Approved image vulnerability/malware management and release controls | Scanning policy and exceptions |
| SEC-07 | Approved production image integrity, provenance and rollback retention | Digest and release/retention evidence |
| SEC-08 | Least privilege and periodic access review | Effective permission matrix and reviews |
| SEC-09 | Documented incident response, credential revocation and security testing | Runbooks and tested controls |

**PCI DSS 4.0.1 mapping for Security review:** requirements 1, 2, 5, 6, 7, 8, 10, 11 and 12 as applicable. The Security/PCI owner must establish the actual CDE/connected-to-CDE scope and accept the segmentation controls. A shared JFrog instance is not inherently prohibited, but a Project/repository name is not sufficient proof of compliant isolation.

## 7. Availability, monitoring and DR

JFrog is a critical **deployment-time dependency**. Running pods may continue during an outage; new pulls, scaling, rescheduling, node replacement and disaster recovery can fail if the required image is not cached. Node-local cache is not an adequate DR guarantee.

| ID | Requirement | Provider commitment |
|---|---|---|
| AVL-01 | Agreed registry availability SLO/SLA and measurement method | TBD |
| AVL-02 | 24x7 ability to pull images for production workloads; documented incident support coverage | TBD |
| AVL-03 | No unmitigated production single point of failure and documented failover | TBD |
| AVL-04 | Sufficient throughput/concurrency for upgrades, scale-out and cluster recovery | TBD |
| AVL-05 | Change/maintenance notice for endpoint, cert, auth, repository and service outages | TBD |
| AVL-06 | Provider-side registry health, error-rate, auth and capacity monitoring | TBD |
| AVL-07 | OpenShift-side monitoring of ErrImagePull, ImagePullBackOff, TLS, DNS, 401/403, timeouts | OpenShift to implement |
| AVL-08 | Defined incident escalation, runbooks, support contacts and ownership | TBD |
| AVL-09 | Documented and tested provider backup/restore and RTO/RPO | TBD |
| AVL-10 | Retain approved production images for rollback and DR; test new-node pull after failure | TBD |

A numeric SLA or RTO/RPO is **not specified without an approved OpenShift/application recovery target**. These are required contractual/service values to agree with the JFrog provider, not implementation choices left unreviewed.

## 8. RACI / support boundaries

| Activity | OpenShift Infrastructure | JFrog Service Team | Other |
|---|---|---|---|
| Service definition and OpenShift consumer standard | Responsible | Consulted | Service management approves TBD |
| Registry endpoints, repositories, credentials and permissions | Requests/validates | Responsible | Security policy |
| Worker egress/DNS/CA integration | Responsible for cluster side | Supplies requirements | Network implements firewall |
| Namespace Secrets and ServiceAccounts | Responsible | Consulted | Application team uses |
| CI image build/push and application references | Integration guidance | Provides registry capability | Application/CI team owns |
| ImagePullBackOff triage | First-line platform diagnosis | Registry-side escalation | Application consulted |
| Registry patching, HA, storage, backup, DR | Informed/validates dependency | Responsible | Service owner |
| PCI scoping and control acceptance | Provides evidence | Provides evidence | Security/QSA accountable |
| Representative application test | Coordinates platform side | Supports registry side | Smart MS/application owner signs off |

**Named coordination:** Johannes Roeske — connectivity and Smart MS/Nexus inputs; Martin Kalata — solution architecture; Michal Mesaros — firewall/network request; JFrog Engineering — provider-side capabilities; Smart MS/Martin Cipra — application requirements; Security — PCI acceptance. Final named RACI approvals: TBD.

## 9. Onboarding and offboarding standard

### Onboarding
1. Record application/tenant owner, namespaces, environment, image paths and PCI classification.
2. Confirm JFrog repository entitlement and read-only machine identity matching the security domain.
3. Confirm worker DNS, TLS trust and approved firewall route.
4. Distribute namespace-local imagePullSecret through approved secret-management automation.
5. Bind Secret to appropriate workload ServiceAccount; avoid unnecessary default/global access.
6. Test authorized image pull from representative worker nodes and denied unauthorized pull.
7. Record credential owner, rotation schedule, repository scope, support contact and acceptance evidence.

### Offboarding
1. Remove workload references and namespace-local pull Secrets.
2. Revoke/restrict JFrog machine identity if no longer used elsewhere.
3. Remove obsolete permissions/network exceptions as applicable.
4. Preserve required access/audit evidence.

## 10. Production acceptance criteria

- [ ] Registry and auth FQDNs, TLS and firewall flows approved and tested from relevant workers.
- [ ] Infrastructure image allocation and ownership agreed; independent permissions demonstrated.
- [ ] Namespace-local pull Secret and ServiceAccount integration validated.
- [ ] Positive pull from authorized tenant; negative pulls across unauthorized customer/PCI boundaries.
- [ ] Pull identity cannot push, overwrite, delete or administer.
- [ ] Token rotation and revocation tested without uncontrolled interruption.
- [ ] Immutable approved image reference, retention and rollback demonstrated.
- [ ] Parallel pulls, new-node pulls and failure/recovery behavior tested.
- [ ] Monitoring, escalation, maintenance and operational ownership approved.
- [ ] SLA, RTO/RPO and provider DR evidence reviewed and accepted.
- [ ] Smart MS representative deployment/rollback accepted.
- [ ] PCI Security and service owner sign-off recorded for relevant environments.

## 11. Open inputs to complete implementation

| Input | Owner | Status |
|---|---|---|
| Registry/auth FQDNs, certificates, supported OCI paths | JFrog / Johannes | TBD |
| Infrastructure repository allocation and permission model | JFrog Engineering | TBD |
| Credential/token lifecycle and effective read-only scope | JFrog Engineering | TBD |
| Worker source IPs, routing, proxy, firewall changes | Network / Solution Design | TBD |
| Smart MS actual image paths, namespaces and pull/push needs | Johannes / Martin Cipra | TBD |
| PCI scope, segmentation and audit evidence | Security / PCI owner | TBD |
| SLA, support coverage, HA, RTO/RPO, DR evidence | JFrog Service Owner | TBD |

## 12. Required statement to JFrog Engineering

> The OpenShift Container Service requires a dedicated, logically segregated allocation for infrastructure-owned container images within the corporate JFrog Artifactory service. This allocation must support independent ownership, repository-scoped access permissions, separate read-only consumption identities and controlled image publishing. The implementation may use an existing JFrog Project or a dedicated Project, provided that the required isolation and access controls are demonstrably enforced. In addition, the service must support direct authenticated image pulls from OpenShift worker nodes, approved network/TLS connectivity, tenant- and PCI-scoped access, documented credential lifecycle, auditability, availability, monitoring, image retention and tested recovery.

## 13. Related tracking
- Earlier technical definition: PR #2.
- Earlier service offering/GAP assessment: PR #3.
- Stakeholder questions and evidence collection: Issue #4.
- Execution plan: PR #5.

This file is **standalone** and does not modify any earlier documents.
