# Jenkins RBAC matrix (template)

CasC ships **plugins** (`matrix-auth`, `role-strategy`) but **does not** guess your human identities. After creating Jenkins users (or enabling OIDC in Phase 2), configure:

| Capability | Example | Notes |
|------------|-------------------|-------|
| Overall/Administer | `svc-jenkins-admins` group | Tier-0 infra owners only |
| Overall/Read | `authenticated` | Baseline dashboard visibility |
| Job/Build | `robotics-operators` | Jetson job runners |
| Job/Configure | `robotics-leads` | Pipeline parameter edits |
| Credentials/View | restricted | Separate Jetson vs OpenStack folders recommended |

Use **folder-scoped roles** so Isaac Sim operators cannot read Jetson SSH credentials.

Document actual LDAP/OIDC group mappings here once integrated.

## Login brute-force

Prefer **rate limiting at the reverse proxy** or VPN posture; Jenkins-specific plugins vary—evaluate before installation.

## Pipeline sandbox & script approvals

- Keep **Pipeline Groovy sandbox** enabled; approve signatures **narrowly** under **Manage Jenkins → In-process Script Approval**—never blanket “approve all”.
- Prefer **Pipeline from SCM** (as seeded here) over freestyle shell for privileged paths.
- After Jenkins upgrades, re-check pending approvals and audit logs—CasC and plugin APIs sometimes drift.

## Audit retention

- **audit-trail** plugin captures configuration changes; retain Jenkins audit logs per your SIEM policy (forward via host journal or container logging driver per `compose-logging.md`).
- Build logs may contain parameter echoes—keep masking enabled where Pipeline supports it.
