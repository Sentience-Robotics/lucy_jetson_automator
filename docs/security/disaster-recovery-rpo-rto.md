# RTO / RPO — controller VPS

Document organization-specific targets here (numbers are placeholders).

| Metric | Target | Notes |
|--------|--------|-------|
| **RPO** (max acceptable data loss for Jenkins state) | _e.g. 24h_ | Align backup cadence + Terraform remote state retention |
| **RTO** (time to restore Jenkins operations) | _e.g. 4h_ | Includes DNS/VPN propagation if IPs change |

## Break-glass bootstrap recovery

1. **Named owner** maintains offline copies of: VPS SSH keys, encrypted backups of `jenkins_home`, Terraform backend credentials (separate from cloud API keys).
2. If Jenkins is compromised: revoke VPN access, rotate OpenStack application credentials, rebuild VPS from trusted image, restore volume from last known-good backup, replay Terraform state verification with `terraform plan`.
3. Never share a single Jenkins “admin” password — individual accounts + MFA on VPN.

Practice this flow at least once per quarter.
