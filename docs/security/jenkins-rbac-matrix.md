# Jenkins RBAC matrix (template)

## Security administrative monitors (tier‑0)

- **Built-in node / distributed builds:** Pipelines use the **`docker` label** (Docker cloud in `jenkins/casc/05-docker-cloud.yaml`); the controller has **`numExecutors: 0`**. The controller image mounts **`/var/run/docker.sock`** and **`JENKINS_DOCKER_SOCK_GID`** in `jenkins/.env` must match the host socket’s group (`stat -c '%g' /var/run/docker.sock`). **`JENKINS_URL`** must be reachable from agent containers (not only `127.0.0.1` unless you add host networking / `extraHosts` for agents).
- **Resource root URL:** Serving workspace artifacts without loosening CSP requires a **second hostname** pointing at the same Jenkins instance (see [Rendering user content](https://www.jenkins.io/doc/book/security/user-content/)). This repo does not set it automatically; add DNS + CasC when you have two names.
- **CSP:** CasC sets **`security.contentSecurityPolicy.enforce: true`**. The old **`DirectoryBrowserSupport.CSP=`** Java override was removed from Compose so the default workspace CSP applies again.
- **Ambiguous matrix permissions:** If the admin monitor lists overlaps, use **Manage Jenkins** guidance to migrate entries, then tighten **folder-scoped** roles so Jetson and OpenStack permissions do not share the same ambiguous `authenticated` grants.

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
