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

Bootstrap is **remote-only**: run Ansible from a machine that can SSH to the VPS (laptop or bastion), not by executing the playbook on the VPS against `localhost`.

1. Join the management VPN.
2. Clone this repository on your **control machine** (not necessarily on the VPS). Copy `.env.example` → `.env` and set **`VPS_SSH_HOST`**, **`VPS_SSH_USER`**, and the variables below.
3. Context for Ansible (in `.env`):
   - `VPS_CONFIGURE_FIREWALL` — when `true`, UFW allows **SSH**, **Jenkins HTTP**, and **agent** TCP ports from any source (no CIDR list in this repo); use provider security groups, VPN, and `VPS_JENKINS_BIND` for real exposure control.
   - `VPS_CONTROLLER_REPO_URL` — Git remote Jenkins jobs clone (`https://…` or `git@…`).
   - `VPS_JENKINS_BIND` — bind published ports (often VPN-facing IP or `127.0.0.1` behind SSH tunnel).
   - `ANSIBLE_BECOME_PASS` or use `-K` if sudo on the **VPS** requires a password.
4. Run: `make ansible-collections`, then `./bootstrap-vps.sh` (or `make bootstrap-jenkins`). The playbook rsyncs the repo to `lucy_infra_root` on the VPS (default `/opt/lucy-infra`).
5. Jenkins home persists in the Docker volume `jenkins_home` on the VPS. Logs (on the VPS): `docker compose -f /opt/lucy-infra/jenkins/docker-compose.yml logs -f jenkins`.

### Tier-0 Jenkins hygiene

- Subscribe to the official Jenkins security advisory feed; schedule **monthly** image/plugin reviews.
- Record plugin bumps in `docs/runbooks/plugin-changes.md`.
- Keep an **offline encrypted backup** of `/var/lib/docker/volumes/jenkins_home` (or the named volume contents) and rehearse restore quarterly; document **RTO/RPO**.

## Jenkins credentials (IDs referenced by pipelines)

The repo root **`.env`** is for **VPS bootstrap** only (`VPS_*` plus required **`VPS_SSH_HOST`** / **`VPS_SSH_USER`**). **Jetson** secrets are **not** in Git: create them under **Manage Jenkins → Credentials** using the **exact IDs** below (the **`lucy/jetson-config`** job description repeats this checklist). The pipeline binds them with `withCredentials` and never commits values.

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

**`lucy/jetson-config` job parameters** (not credentials): `GIT_REF`, `ANSIBLE_TAGS`, and **`SETUP_ISAAC_ROS`** (boolean) are defined in Job DSL and appear on **Build with Parameters**; the pipeline exports `SETUP_ISAAC_ROS` for Ansible.

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
