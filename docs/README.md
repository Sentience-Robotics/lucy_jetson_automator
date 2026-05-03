# Operations runbooks

| Document | Purpose |
|----------|---------|
| [vpn-topology-and-mfa.md](vpn-topology-and-mfa.md) | VPN plane, MFA assumption, split-tunnel API egress |
| [backup-jenkins-volume.md](backup-jenkins-volume.md) | Encrypted backup / restore of Jenkins Docker volume |
| [disaster-recovery-rpo-rto.md](disaster-recovery-rpo-rto.md) | RTO/RPO targets and quarterly restore drill |
| [jenkins-patch-upgrade-checklist.md](jenkins-patch-upgrade-checklist.md) | Tier-0 patch window / rollback digest |
| [jenkins-security-advisories.md](jenkins-security-advisories.md) | CVE/advisory subscription & cadence |
| [jenkins-rbac-matrix.md](jenkins-rbac-matrix.md) | RBAC matrix template & script-security posture |
| [compose-logging.md](compose-logging.md) | Central logging via Compose / journald |
| [break-glass-bootstrap-recovery.md](break-glass-bootstrap-recovery.md) | Emergency recovery ownership / steps |
| [vault-and-oidc-phase2.md](vault-and-oidc-phase2.md) | Vault roadmap & OIDC go-live triggers |
| [ci-required-checks.md](ci-required-checks.md) | Branch protection & required CI checks |
| [plugin-changes.md](plugin-changes.md) | Jenkins plugin change log |

## Network posture

- Jenkins UI and SSH on the VPS are **VPN-only**. WAN ingress should remain **default deny** except what your VPN design requires.
- The VPS uses **public HTTPS egress** for Git, container registries, OpenStack (`auth.openstack`), plugin mirrors, Terraform remote backends, and OS updates. Validate **split tunneling** so VPN default routes do not block API egress.

## Bootstrap the VPS controller

1. Join the management VPN and SSH to the VPS.
2. Clone this repository to `/opt/lucy-infra` (or another path — `lucy_infra_root` defaults to `/opt/lucy-infra`).
3. Export context for Ansible:
   - `VPS_VPN_ALLOW_CIDR` — VPN subnet allowed to reach SSH + Jenkins (required when `VPS_CONFIGURE_FIREWALL=true`).
   - `VPS_CONTROLLER_REPO_URL` — Git remote Jenkins jobs clone (`https://…` or `git@…`).
   - `VPS_JENKINS_BIND` — bind published ports (often VPN-facing IP or `127.0.0.1` behind SSH tunnel).
   - `ANSIBLE_BECOME_PASS` or use `-K` if sudo requires a password.
4. Run: `./bootstrap-vps.sh` (or `make bootstrap-jenkins`).
5. Jenkins home persists in the Docker volume `jenkins_home`. Logs: `docker compose -f /opt/lucy-infra/jenkins/docker-compose.yml logs -f jenkins`.

### Tier-0 Jenkins hygiene

- Subscribe to the official Jenkins security advisory feed; schedule **monthly** image/plugin reviews.
- Record plugin bumps in `docs/runbooks/plugin-changes.md`.
- Keep an **offline encrypted backup** of `/var/lib/docker/volumes/jenkins_home` (or the named volume contents) and rehearse restore quarterly; document **RTO/RPO**.

## Jenkins credentials (IDs referenced by pipelines)

Create these in Jenkins (folder `lucy` inherits or global depending on your layout):

| Credential ID | Type | Purpose |
|---------------|------|---------|
| `jetson-host` | Secret text | `JETSON_HOST` (VPN DNS/IP) |
| `jetson-ssh-key` | SSH username + private key | SSH auth (username + key) |
| `jetson-password` | Secret text | Ansible become / sudo password |
| `jetson-hostname` | Secret text | Optional `JETSON_HOSTNAME` |
| `jetson-wifi-ssid` | Secret text | Optional Wi‑Fi SSID |
| `jetson-wifi-password` | Secret text | Optional Wi‑Fi password |
| `jetson-jetpack-version` | Secret text | e.g. `6.2` |
| `openstack-clouds-yaml` | Secret file | Standard OpenStack `clouds.yaml` for OVH |

Never commit secrets; prefer Jenkins credentials or Phase‑2 Vault integration.

## Isaac Sim Terraform backend

- Production **must** use a **remote backend with locking** (see `terraform/ovh-instance-lifecycle/backend.tf.example`).
- CI runs `terraform init -backend=false`; Jenkins should run full `terraform init` with backend configuration supplied via mounted `-backend-config` files or pipeline secrets.

## Incident lockdown

- Revoke VPN accounts for departed operators first.
- Rotate Jenkins credentials (`jetson-*`, `openstack-clouds-yaml`) and OpenStack application credentials.
- Snapshot Jenkins logs (`docker compose logs`) before destructive changes.

## OIDC / Vault triggers

- Enable Jenkins OIDC when **>3 operators**, **any contractor VPN access**, or a **compliance milestone** occurs—whichever comes first.
- Vault/agent integration replaces static Jenkins secrets when compliance requires short-lived tokens.

## Credential rotation

- Rotate Jetson and OpenStack credentials on schedule and after any suspected compromise; update Jenkins credential entries—never commit secrets to the repo.
