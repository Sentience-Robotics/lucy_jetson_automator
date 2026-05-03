# Jenkins tier-0 patch / upgrade checklist

Use monthly or upon Jenkins security advisory publication.

1. **Read** the Jenkins security advisory for your LTS line.
2. **Base image**: `jenkins/Dockerfile` uses `jenkins/jenkins:lts-jdk21` (moving LTS tag). Rebuild with **`docker compose build --pull`** (or `docker build --pull`) so each upgrade picks up the current LTS image without editing `FROM`. Optionally switch back to a digest pin for stricter reproducibility.
3. **Plugins**: `jenkins/plugins.txt` has IDs only (no versions). Each **`docker compose build --pull`** resolves latest compatible plugins for the current LTS controller. After advisories, **rebuild with `--pull`**; edit the file only to **add/remove** plugins or pin a specific version temporarily if you must hold one plugin back.
4. **Record** changes in `docs/runbooks/plugin-changes.md`.
5. **Build** locally or on staging: `docker compose build` under `/opt/lucy-infra/jenkins`.
6. **Smoke-test**: login, run “Replay” on a non-production folder job, verify CasC loads (`Manage Jenkins → Configuration as Code`).
7. **Rollback plan**: keep previous image digest available (`docker images lucy-jenkins:local` tagging scheme optional).
8. **Deploy** during maintenance window on VPN; capture controller logs before/after.

Subscribe to: https://www.jenkins.io/security/advisories/
