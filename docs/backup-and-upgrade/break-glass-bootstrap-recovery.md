# Break-glass bootstrap recovery

## Ownership

- Assign **one primary** and **one secondary** named owner responsible for VPS bootstrap recovery (document names in your internal ops wiki, not in Git).

## Recovery scenarios

1. **Jenkins UI unreachable but SSH works** — verify VPN, UFW (`ufw status`), and Jenkins bind address (`VPS_JENKINS_BIND` / `/opt/lucy-infra/jenkins/.env`). Restart stack: `docker compose -f /opt/lucy-infra/jenkins/docker-compose.yml restart`.
2. **Corrupted `$JENKINS_HOME`** — restore from latest encrypted volume backup per `backup-jenkins-volume.md`, then restart Compose.
3. **Lost Admin access** — use Jenkins documented unlock procedures for your install path (initial password file only if wizard path still applies); otherwise restore from backup volume.

## Rotation discipline

- No shared long-lived Jenkins “admin” password.
- After break-glass use, **rotate** all credentials touched during recovery (Jetson SSH keys passwords, OpenStack application credentials, Git deploy tokens).
