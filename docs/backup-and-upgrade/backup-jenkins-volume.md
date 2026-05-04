# Backup and restore: Jenkins `jenkins_home` volume

## What to back up

Docker Compose defines a named volume `jenkins_home` attached to the Jenkins container. It holds plugins, job configuration, credentials metadata, and build history.

Locate the volume:

```bash
docker volume inspect lucy-infra_jenkins_home
# or similar prefix from the Compose project name under /opt/lucy-infra/jenkins
```

## Backup (encrypted off-box)

1. Stop Jenkins gracefully (optional, reduces inconsistency):
   ```bash
   cd /opt/lucy-infra/jenkins && docker compose stop jenkins
   ```
2. Archive the volume directory Docker stores (path from `docker volume inspect`) **or** run a temporary Alpine container mounting the volume and `tar` `/var/jenkins_home`.
3. Encrypt the archive (e.g. `age`, `gpg`, or tooling mandated by your org) before copying to object storage or another region.
4. Start Jenkins again:
   ```bash
   docker compose start jenkins
   ```

## Restore drill (quarterly)

1. Provision a fresh VPS or wipe `/opt/lucy-infra` **only** in a test environment.
2. Restore the encrypted archive into a fresh Docker volume named to match Compose expectations **or** restore files under the volume mount path.
3. Run `./bootstrap-vps.sh` with matching firewall/env vars; reuse restored volume instead of creating empty data when validated.
4. Document observed **RTO** (time to usable Jenkins) and **RPO** (acceptable credential/job loss window).

See also `docs/runbooks/disaster-recovery-rpo-rto.md`.
