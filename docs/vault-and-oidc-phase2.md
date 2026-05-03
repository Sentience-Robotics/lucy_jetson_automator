# Vault and OIDC — Phase 2 roadmap

## OIDC for Jenkins — go-live triggers

Implement Jenkins **OIDC** (backed by your corporate IdP) when **any** of the following is true—whichever comes first:

1. More than **three** humans have VPN access that can reach Jenkins, **or**
2. **Any contractor** receives VPN access that can reach Jenkins, **or**
3. A **compliance milestone** (customer audit, cyber insurance, contractual control) requires centralized identity.

Until then: VPN MFA + Jenkins local accounts + matrix authorization (see `jenkins-rbac-matrix.md`) + audit logging discipline.

## Checklist (concise)

- [ ] Register Jenkins as OIDC client (confidential); redirect URIs for VPN-only Jenkins base URL (`JENKINS_URL`).
- [ ] Map IdP groups to Jenkins roles/folders (Jetson operators vs Isaac Sim operators vs admins).
- [ ] Disable or archive unused local interactive accounts; retain **one** break-glass procedure documented in `break-glass-bootstrap-recovery.md`.
- [ ] Re-validate script approvals and Pipeline-from-SCM-only posture after IdP cutover.

## Vault / short-lived secrets

**Goal:** replace static Jenkins credential blobs with short-lived tokens where policy requires it.

- Prefer **Vault Agent** or CSI patterns that inject secrets at runtime without persisting them on disk for operators.
- Scope OpenStack application credentials to a **single project**; split read vs write roles where APIs allow; rotate on schedule (see main runbook README credential rotation).
- Keep **backup encryption keys** separate from cloud API credentials where feasible.

Document chosen Vault integration (agent vs CSI vs Jenkins plugin) in your internal wiki—avoid committing environment-specific endpoints to this repo.
