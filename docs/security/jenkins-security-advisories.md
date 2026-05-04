# Jenkins security advisories (tier‑0)

## Subscribe

- Official advisories: [Jenkins Security Advisories](https://www.jenkins.io/security/advisories/) (RSS available from that index).
- Track **core LTS** and **installed plugins** together—many CVEs land in plugins, not the WAR alone.

## Cadence

- **Monthly** maintenance window: review advisories, bump controller digest/plugins per `jenkins-patch-upgrade-checklist.md`, and record changes in `plugin-changes.md`.
- After any advisory rated **high/critical** affecting core or installed plugins, treat review as **out-of-band** (within your internal SLA).

## Evidence

- Export `jenkins-core-version` and installed plugin versions periodically (script console or `pluginManager` API) and attach to change tickets when upgrading.
