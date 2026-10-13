# JFrog Container Registry Consumption — OpenShift Container Service Description

**Document status:** Draft for DNPC Service Owner, JFrog Engineering and Security review  
**Version:** 0.1 | **Date:** 2026-10-13  
**Parent offering:** DN Private Cloud OpenShift Container Service  
**Service owner:** OpenShift Infrastructure / Container Platform Team  
**Upstream dependency:** Centrally operated JFrog Artifactory

## 1. Purpose

This document describes the JFrog Container Registry Consumption capability provided as part of the DN Private Cloud (DNPC) OpenShift Container Service. It defines the customer-facing service, its scope, prerequisites for consumption, service elements, responsibilities, ordering, operational dependencies and lifecycle considerations.

This document does **not** define the internal architecture of JFrog or prescribe its repository/project topology. Detailed OpenShift-to-JFrog technical and security requirements and GAP analysis are maintained separately.

## 2. Summary

The service enables authorized applications deployed on DNPC OpenShift to retrieve approved OCI/Docker container images from the corporate JFrog Artifactory service. Image pulls are performed directly by OpenShift worker-node container runtimes using secure registry connectivity and appropriately scoped credentials. OpenShift provides the cluster-side integration and operational support; JFrog Engineering provides and operates the registry.

The capability is available only after the required network, registry access, credential and security prerequisites have been met and a representative image pull has been validated.

## 3. Scope and service boundaries

### 3.1 In scope
- Integration of approved JFrog OCI/Docker registries for image consumption by OpenShift workloads.
- Cluster-side DNS, routing, TLS trust and connectivity coordination/validation.
- Approved namespace-scoped image pull credential configuration and ServiceAccount association.
- Onboarding and offboarding guidance for authorized application tenants.
- OpenShift-side image pull validation, troubleshooting, monitoring and escalation.
- Coordination of required security controls for tenant separation and PCI-scoped workloads.

### 3.2 Out of scope
- Installation, upgrade, patching, backup, storage, HA and internal administration of JFrog.
- Repository creation and JFrog-side RBAC administration, unless explicitly delegated by the registry service owner.
- Application image build, publishing, scanning, approval and content ownership, except separately contracted platform-owned artifacts.
- Application release management and application-level disaster recovery.
- Guarantee of upstream JFrog SLA beyond agreed provider commitments.

## 4. Service Description

The JFrog Container Registry Consumption capability provides a standardized and secure means for authorized OpenShift tenants to pull container images from centrally managed JFrog Artifactory repositories. It supports application deployment, restart, scaling and recovery scenarios requiring access to images that are not already available on worker nodes.

Registry access is implemented through Docker/OCI Distribution API-compatible endpoints. The OpenShift worker-node runtime (CRI-O) initiates the image pull; application Pods do not need direct network access to JFrog merely for their images to be pulled. Access is authenticated using approved non-human registry credentials, scoped to authorized repositories and delivered using the OpenShift-supported imagePullSecret mechanism.

The service is a component of the OpenShift Container Service and depends on the availability, security and operational commitments of the corporate JFrog platform.

### 4.1 Service consumers
Authorized DNPC OpenShift tenants, application owners and platform service owners requiring private or approved shared container images.

### 4.2 Service delivery model
The OpenShift team provides the consumer integration. JFrog Engineering supplies registry endpoints, repositories, access entitlements and registry operations. Network and Security teams approve relevant connectivity and security boundaries. Application teams own image content and workload deployment definitions.

## 5. Requirements / prerequisites for service consumption (DNPC template §3.1.1)

The following conditions must be fulfilled **before** an application may consume private JFrog images through OpenShift. These are customer and provider onboarding prerequisites, not a mandate to implement a particular JFrog topology.

| ID | Prerequisite | Description / acceptance |
|---|---|---|
| REQ-01 | Provisioned OpenShift tenant | The customer/application has an approved OpenShift namespace/project and designated technical owner. |
| REQ-02 | Approved repository | Required OCI/Docker images are hosted in an approved JFrog repository and the consumer's entitlement is authorized. |
| REQ-03 | Registry endpoint | The JFrog provider supplies the actual registry FQDN, port, image reference format and any separately reachable auth/download endpoints. |
| REQ-04 | Worker-node connectivity | Approved outbound network path from relevant OpenShift worker-node egress/NAT addresses to all endpoints required for image pulls. |
| REQ-05 | DNS resolution | Registry and required authentication/download hostnames resolve from the worker-node environment. |
| REQ-06 | TLS trust | Valid registry TLS certificates and approved trust chain are available to OpenShift nodes; any enterprise CA integration follows supported OpenShift procedures. |
| REQ-07 | Registry identity | A non-human registry identity/token is provisioned through the approved JFrog access process. |
| REQ-08 | Least-privilege access | Runtime identity has read/pull permission only for authorized images and no unnecessary push/delete/admin rights. |
| REQ-09 | Image pull Secret | Registry credentials are securely delivered to a namespace-local `kubernetes.io/dockerconfigjson` Secret and referenced by the appropriate workload ServiceAccount or Pod. The operating team responsible for secret provisioning is determined by the agreed onboarding model. |
| REQ-10 | Image availability | Required image names, tags/digests and CPU architecture are valid and compatible with supported OpenShift/CRI-O runtimes. |
| REQ-11 | Security and tenant scope | Tenant, environment and PCI/non-PCI boundaries and access entitlements are assessed and approved where applicable. |
| REQ-12 | Credential lifecycle | Credential owner, expiry, rotation, emergency revocation and secure distribution procedure are defined. |
| REQ-13 | Support ownership | Application, OpenShift, JFrog and Network contacts and incident escalation are recorded. |
| REQ-14 | End-to-end validation | A representative authenticated image pull succeeds from the target environment, and restricted access is denied as expected. |
| REQ-15 | Image governance | Required image approval, provenance, vulnerability and retention policies are fulfilled by the responsible image/repository owners. |

**Note:** The JFrog UI address is not necessarily the Docker/OCI registry endpoint. The exact endpoint, authentication flow and any redirects must be confirmed by the provider. Firewall source selection must reflect actual worker-node egress/NAT/proxy behavior, not assumed Pod CIDRs.

## 6. Service Levels (DNPC template §3.1.2)

The capability is dependent on both the OpenShift Container Service and the upstream JFrog service. End-to-end image-pull availability may be affected by registry, network, DNS, TLS, authentication or repository incidents.

- **Service availability:** Governed by the approved OpenShift service level and confirmed JFrog dependency commitments (**TBD**).
- **Support hours and incident priority:** As defined in the applicable DNPC support agreement and JFrog service agreement (**TBD**).
- **Planned maintenance:** Endpoint, certificate, permission and token-policy changes with possible consumption impact require coordinated change communication.
- **Service exclusions:** Existing running workloads may remain available during a registry outage; new image pulls, scaling, rescheduling and recovery may fail. Cached images are not a recovery guarantee.
- **Performance:** Image-pull performance depends on registry throughput, image size, worker concurrency and network capacity.

No numeric availability, recovery or support commitment is assumed until approved by the relevant service owners.

## 7. Service Elements Included (DNPC template §3.1.3)

| Element | Included capability |
|---|---|
| Registry integration | Consumption of approved JFrog OCI/Docker endpoints from OpenShift worker nodes |
| Network integration | Coordination and verification of worker-to-registry connectivity |
| Secure authentication | Integration of approved machine credentials through namespace-local image pull Secrets |
| Authorization enforcement | Consumer access limited by JFrog repository entitlements; OpenShift controls credential distribution |
| Tenant onboarding | Standard prerequisite review, configuration and test procedure |
| Operations | OpenShift-side diagnostics, alerts/monitoring integration and escalation |
| Change management | Coordination of endpoint, certificate, credential and relevant platform changes |
| Offboarding | Removal of namespace credentials and coordination of registry entitlement revocation |

## 8. Service Classes (DNPC template §3.1.4)

The registry consumption capability is provided within the service class of the consuming OpenShift environment. It does not independently create a Gold/Silver/Bronze entitlement or elevate the upstream JFrog service level. Any differentiated availability, recovery, performance or support commitments must be explicitly confirmed in the DNPC service catalogue and the JFrog provider agreement (**TBD**).

## 9. Backup and Recovery (DNPC template §3.1.5)

- **JFrog provider:** Owns repository/artifact storage protection, backups, restore capability, replication where applicable and provider-side disaster recovery. Recovery targets and evidence: **TBD**.
- **OpenShift Infrastructure:** Owns recovery of supported cluster-side integration configuration, including trusted CA configuration and approved Secret delivery mechanisms, according to OpenShift platform procedures.
- **Application owner:** Owns the application deployment state, required image references, release/rollback planning and application-level recovery.
- **Validation:** Recovery exercises should verify that an image can be pulled onto a replacement worker node and that required rollback images remain available.

RTO and RPO are not specified until formally agreed with the relevant service owners.

## 10. Service Order / Request Fulfilment (DNPC template §3.1.6)

An application owner requests JFrog registry consumption through the approved DNPC service request channel (**SMAX catalogue item / request route TBD**).

The request should contain:
1. Application and technical owner, business service and tenant/namespace.
2. Target OpenShift cluster/environment and production/PCI classification.
3. JFrog registry hostname and authorized image repository paths.
4. Required consumer access scope and designated registry identity owner.
5. Expected onboarding date and any exceptional image-pull capacity requirements.
6. Support contacts and any security/network approvals already obtained.

**Fulfilment:** Confirm repository entitlement → verify registry endpoint and network prerequisites → provision/validate approved registry credentials → configure namespace pull Secret/ServiceAccount → perform positive and negative access tests → record operational handover.

## 11. Supported Versions and Lifecycle (DNPC template §3.1.7)

Supported consumers are the OpenShift versions and CRI-O runtime configurations within the active DNPC OpenShift Container Service lifecycle. The upstream JFrog endpoint must support compatible Docker/OCI registry distribution protocols and approved TLS/authentication methods.

Exact OpenShift versions, registry compatibility statements, certificate lifecycle and deprecation notice periods are maintained by their respective service owners (**TBD**). Image architecture and manifest compatibility must be validated per application.

## 12. Security, compliance and customer responsibilities

- Access is granted on a least-privilege basis; personal credentials are not approved for unattended production image pulls.
- Registry credentials must not be stored in Git repositories, container images or unprotected deployment manifests.
- Customer-private images must not be made available to unauthorized tenants.
- Shared images may be accessible across tenants only under approved entitlement policies.
- PCI-scoped consumption requires Security/PCI-owner review of the applicable access, audit and segmentation controls. A separate JFrog instance or Project is not automatically required; demonstrated isolation and scope assessment are required.
- Application/image owners remain accountable for image content, supported architectures, provenance, scanning policy and release governance.
- Consumers must notify the service owner of changed repository paths, credentials, security classification or support ownership.

## 13. Roles and Responsibilities

| Activity | OpenShift Team | JFrog Team | Other responsible party |
|---|---|---|---|
| OpenShift service definition and cluster-side integration | Responsible | Consulted | DNPC service owner approval |
| JFrog registry availability and internal administration | Informed | Responsible | — |
| Repository provisioning, registry identities and permissions | Requests/validates | Responsible | Security as applicable |
| Worker-side network/TLS integration | Coordinates and validates | Supplies endpoints | Network implements/approves rules |
| Namespace pull Secrets and ServiceAccounts | Responsible under agreed operating model | Consulted | Application owner provides scope |
| Build/push/image content and deployment image references | Consulted | Registry service provided | Application/CI team responsible |
| Registry-side incidents, backup and DR | Escalates and validates | Responsible | Service management |
| Tenant/PCI security acceptance | Supplies integration evidence | Supplies access evidence | Security/PCI owner approves |

## 14. Service limitations and assumptions

- The service covers **image pulls**, not general-purpose application API traffic to JFrog.
- Direct worker-node-to-JFrog connectivity is the selected integration pattern; Harbor mirroring or an intermediate registry is not assumed.
- A dedicated JFrog Project is not a prerequisite if existing repository allocation and permissions satisfy approved isolation requirements.
- Cluster-wide credentials shared across unrelated tenants are not the default pattern.
- Successful integration requires both reachable registry endpoints and valid authorization; network connectivity alone does not guarantee successful image pulls.
- Any unconfirmed service catalogue terms remain **TBD** and must not be treated as contractual commitments.

## 15. Definitions

| Term | Meaning |
|---|---|
| OCI | Open Container Initiative; standards for container images and distribution |
| Registry endpoint | Hostname/port and API entry point used to retrieve container images |
| CRI-O | OpenShift container runtime performing worker-node image pulls |
| ImagePullSecret | Namespace-local Kubernetes Secret holding registry authentication data |
| ServiceAccount | Namespace-scoped Kubernetes workload identity referencing pull credentials |
| FQDN | Fully Qualified Domain Name |
| RTO / RPO | Recovery Time Objective / Recovery Point Objective |
| PCI DSS | Payment Card Industry Data Security Standard |
| GAP assessment | Comparison of defined requirements against existing provider capabilities |

## 16. References and related documents

- DNPC OpenShift Container Service catalogue and applicable support/SLA documents — **reference TBD**.
- Corporate JFrog Service Offering, repository access standard and operational runbooks — **reference TBD**.
- OpenShift-to-JFrog detailed requirements and GAP assessment — maintained separately in the repository.
- Security/PCI segmentation and identity management standards — **reference TBD**.
- Existing JFrog GitHub work: PR #2, PR #3, issue #4 and PR #6.

## 17. Document history and approvals

| Version | Date | Change | Status |
|---|---|---|---|
| 0.1 | 2026-10-13 | Initial DNPC template-aligned Service Description | Draft |

**Approvals required:** OpenShift Service Owner, JFrog Service Owner, Network (connectivity), Security/PCI (where in scope), DNPC Service Management (catalogue terms).
