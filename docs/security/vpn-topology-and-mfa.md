# VPN topology and MFA assumptions

## Plane

- Operators reach **SSH on the VPS** and the **Jenkins UI** only after joining the **management VPN** that also routes (or DNS-resolves) to **Jetson** automation targets.
- **OVH Public Cloud / OpenStack**, **Git**, **Terraform remote backend**, and **plugin/update mirrors** are reached from the VPS over **public HTTPS egress**, not via the VPN tunnel unless your design intentionally proxies them.

## MFA

- The authoritative MFA boundary is your **VPN IdP** (every human with VPN access uses MFA). Jenkins **local accounts** stay least-privilege and individual—no shared “break glass admin” password culture.
- When triggers in `vault-and-oidc-phase2.md` fire, move Jenkins authentication to **OIDC** aligned with the same IdP.

## Split tunnel

- If the VPN pushes a **default route** through the tunnel, confirm OpenStack/Terraform/Git/API traffic still egresses the VPS public interface as intended. Fix split-tunnel routes or add explicit policies before relying on Isaac Sim or plugin installs.
