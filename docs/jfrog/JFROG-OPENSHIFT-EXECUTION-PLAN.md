# JFrog consumption for OpenShift — execution plan and service standard
**Status:** Draft / 2026-10-13  
**Owner:** OpenShift Infrastructure  
**Integration:** Direct image pull from OpenShift workers to JFrog  
**Related:** PR #2 (earlier definition), PR #3 (service offering/GAP draft). This is an independent execution guide.

## What Stuart expects
JFrog is a dependency within the OpenShift Container Service offering. Deliver (1) a consumer-facing Service Definition, (2) a working OpenShift integration, and (3) a traceable comparison of OpenShift + representative Smart MS application requirements against the existing JFrog offering. **Do not design or administer JFrog itself.**

## Service definition — proposed standard
**Service:** Managed registry consumption for OpenShift tenant workloads.  
**Consumer experience:** An onboarded namespace can deploy approved container images from authorized JFrog registry paths without manually handling long-lived credentials.  
**Prerequisites:** Approved tenant/namespace; image path(s); classification/PCI scope; registry identity and repository permission approval; worker egress and TLS trust; application owner; operational contacts.  
**OpenShift delivers:** Worker-node connectivity, namespace-local pull-secret distribution, ServiceAccount attachment, image-pull validation, documented onboarding/offboarding, incident triage.  
**JFrog Engineering delivers:** Registry endpoints and certificates, repository allocation and permissions, machine credentials/token capabilities, upstream service SLA/HA/DR, audit/security controls.  
**Application team delivers:** Image list/paths, deployment references, namespace/environment inventory, build/push needs, rollback requirements and acceptance testing.  
**Network/Architecture:** Firewall and approved diagrams. **Security:** PCI scope and segregation acceptance.

**Boundary:** We require logical Infrastructure repository ownership and least-privilege access. A new JFrog Project is **optional**, subject to existing offering and evidence; existing 'systems' or another project may be sufficient. Do not mandate repository internals.

## OpenShift consumption model
```
Tenant workload references JFrog image
       -> namespace ServiceAccount + imagePullSecret
       -> kubelet/CRI-O on OpenShift worker node
       -> DNS / routed TLS egress / firewall
       -> JFrog registry/auth endpoint
```
- Source is worker-node egress (not necessarily pod egress); node-level path must be tested.
- TCP/443 is a candidate only; actual registry/auth FQDN, ports, proxy, TLS CA and egress IPs are **TBD**.
- Read-only JFrog machine identity per tenant/security domain as default; a single identity may serve multiple namespaces **within the same trust boundary** by distributing separate namespace-local Secrets. No default sharing across customers or PCI/non-PCI.
- Pull credentials must be securely provisioned, rotated and revoked. Avoid hard-coded tokens in Git.
- Determine whether any CI build/push needs separate write identity; do not grant write rights to runtime pull identity.
- Verify image pull on representative worker nodes, new nodes, after credential rotation and after revocation.
- Use immutable digests for controlled releases where application policy requires; retention must cover rollback.

## Required service properties and acceptance
| Area | OpenShift-side requirement | Provider evidence / TBD |
|---|---|---|
| Availability | Agreed service availability/support windows and escalation | SLA, incidents, maintenance: TBD |
| RBAC | Read-only pull, scoped repository access, no cross-tenant access | Effective permissions and negative tests: TBD |
| PCI DSS | Security-approved CDE boundary and connected-to-CDE assessment | Scope and segmentation signoff: TBD |
| Secrets | Per-domain machine identities, secure storage and rotation | Token model, rotation/revocation: TBD |
| Network | Worker nodes reach registry/auth over approved TLS egress | Endpoints, ports, firewall, DNS, CA: TBD |
| Audit | Access/admin events with approved retention and SIEM handling | JFrog logging evidence: TBD |
| Supply chain | Approved images, vulnerability policy, integrity/retention | JFrog/AppSec controls: TBD |
| Operations | Pull-failure monitoring, owner/on-call, incident escalation | Runbooks and contacts: TBD |
| DR | Registry restoration or failover supporting new-node deployments | RTO, RPO, tests and DR endpoint: TBD |

An existing JFrog repository hierarchy (common, systems, ps, security; dev/qa/releases/deliveries/prod) is visible in internal screenshots, but **does not prove** effective tenant isolation, PCI suitability, Docker image availability under systems, or support for the requested access model.

## Implementation phases and deliverables
### Phase A — Collect evidence (no production changes)
1. Johannes: obtain registry/auth endpoint, Nexus baseline and Smart MS application consumption requirements; identify JFrog service owner.
2. JFrog Engineering: provide service offering, repository ownership/access model, machine-identity model, SLA, HA/DR and audit/security evidence.
3. Smart MS (via Johannes / Martin Cipra): provide actual image/namespace inventory, deployment flows, tenant/PCI classification and acceptance criteria.
4. Martin Kalata / Michal Mesaros: map worker egress and prepare architecture/firewall change.
5. Security: decide PCI scope and minimum isolation/testing requirements.

### Phase B — Requirements vs offering GAP
For every requirement record **requirement / offering / evidence link / MEETS, PARTIAL, GAP or TBD / owner / action / date**. Do not classify TBD as GAP. Raise change requests to JFrog only for confirmed shortfalls.

### Phase C — OpenShift implementation
1. Obtain change approvals and exact endpoint/network configuration.
2. Configure/test DNS, firewall and trusted CA from each relevant worker pool.
3. Request scoped read-only JFrog identities; distribute namespace-local pull Secrets through approved process.
4. Bind pull Secrets to workload ServiceAccounts; verify real image pulls and redeployment.
5. Test denied cross-tenant access, credential revocation/rotation and error escalation.
6. Execute Smart MS deployment/rollback acceptance and document runbooks.
7. Obtain JFrog, OpenShift, Smart MS, Network and Security acceptance.

## Definition of done
- [ ] Service offering, ownership and support responsibilities approved
- [ ] Smart MS requirements confirmed
- [ ] Connectivity design approved and worker-node pulls verified
- [ ] Repository and machine identity scope validated
- [ ] PCI Security assessment and access isolation tests accepted
- [ ] Monitoring, support, SLA, backup/DR and retention agreed
- [ ] GAP register closed or formally risk-accepted
- [ ] Smart MS representative rollout and rollback demonstrated
- [ ] Service Definition published and implementation handover completed

## Current blockers / TBD
JFrog endpoint and auth architecture; exact repository allocation; project vs repo boundary; source networks; CI push requirements; PCI scope; credential policy; SLA; support contacts; DR targets; audit evidence; Smart MS image inventory. **No production implementation is asserted.**

## Separate action tracking
See the GitHub issue **“JFrog/OpenShift — stakeholder questions and evidence collection”** for exact people, questions, required outputs and checkboxes.
