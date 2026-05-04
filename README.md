# Lucy Jetson + VPS automation

Ansible roles and playbooks for **NVIDIA Jetson AGX Orin**, plus a **tier‑0 Jenkins controller** on a VPS (Docker Compose, CasC, Job DSL). The **root `Makefile` only bootstraps Jenkins** over SSH from your control machine to the VPS; Jetson apply, tuning, and secrets are handled **from Jenkins** (or directly on hosts / in repo config), not via Make targets.

## Quick start (Jenkins on VPS)

### Prerequisites
- VPN access to the VPS (for SSH and Jenkins UI)
- [Ansible](https://docs.ansible.com/) on a **control machine** (laptop or bastion) that can reach the VPS over VPN via SSH; the bootstrap playbook always applies to the **VPS** over SSH, never to `localhost` as the controller host.

### Steps
```bash
git clone <repository-url>
cd lucy_jetson_automator
cp .env.example .env
# Edit .env: VPS_SSH_HOST, VPS_SSH_USER, and VPS_* (bootstrap is remote-only over SSH)
make ansible-collections
make validate-env-vps
make bootstrap-jenkins
# equivalent: ./bootstrap-vps.sh
```

See **`.env.example`** for VPS/bootstrap variables only. **Jetson** host, user, passwords, Wi‑Fi, SSH keys, and JetPack version are **only** in Jenkins: open **`lucy/jetson-config`** → read the job description for the credential checklist → **Manage Credentials** to create each ID, then **Build with Parameters** (see `docs/README.md`).

## VPS automation hub (tier‑0)

Management Jenkins runs on a **VPS** reachable only over **VPN** (SSH + UI). Bootstrap installs Docker, optional **UFW** (default deny inbound; allow SSH + Jenkins TCP when `VPS_CONFIGURE_FIREWALL=true` — no source CIDR in-repo; tighten with cloud SGs or bind addresses), and starts Jenkins via Compose with a persistent volume.

Put **VPS bootstrap settings in the repo root `.env`** (see `.env.example`): `VPS_CONTROLLER_REPO_URL`, optional `VPS_JENKINS_URL`, `ANSIBLE_BECOME_PASS`, etc. **`make bootstrap-jenkins` and `./bootstrap-vps.sh` both load `.env`** (Make uses `-include .env`; the script `source`s it).

Set **`VPS_SSH_HOST`** and **`VPS_SSH_USER`** in `.env` (required); optional **`VPS_SSH_PORT`**, **`VPS_SSH_PRIVATE_KEY_FILE`**. Join VPN, run **`make ansible-collections`** once on the control machine, then **`make validate-env-vps`** and **`make bootstrap-jenkins`** (or **`./bootstrap-vps.sh`**; add **`--check`** for a dry run). The playbook rsyncs this repo to **`lucy_infra_root`** on the VPS.

Use **`ANSIBLE_BECOME_PASS`** in `.env` for sudo on the VPS, or pass **`-K`** / **`--ask-become-pass`** on the command line. Anything that must stay out of Git (e.g. Jenkins UI–created credentials) stays in Jenkins, not in `.env`.

Operational detail: [docs/runbooks/README.md](docs/runbooks/README.md) and [ansible/ARCHITECTURE.md](ansible/ARCHITECTURE.md).

**Inventories:** Jetson lab hosts use `ansible/inventory/jetson-lan/`; automation from the VPS over VPN uses `ansible/inventory/jetson-vpn/`. Prefer **`lucy/jetson-config`** for applies; ad‑hoc `ansible-playbook` from a shell requires you to export the same variable names yourself (no repo env template for secrets).

## 🏗️ Architecture

The setup follows a **performance-first, modular architecture** with optimized execution order:

### **Execution Phases**
1. **⚡ Performance Optimization** - jetson_clocks, MAXN power mode, CPU governors  
2. **🏗️ System Foundation** - Package updates and essential utilities
3. **🌐 Network Configuration** - Hostname, Wi-Fi, monitoring services
4. **🔐 Security Hardening** - SSH keys and access controls
5. **🐳 Container Platform** - Docker + NVIDIA Container Runtime
6. **🤖 Isaac ROS Platform** - ROS 2 Humble + Isaac ROS (optional)
7. **👤 User Environment** - Shell configuration and development tools

The playbook can automatically deploy your public key if `SSH_PUBLIC_KEY_PATH` is set.

## Makefile targets (initial bootstrap only)

| Target | Purpose |
|--------|---------|
| `make help` | List targets |
| `make ansible-collections` | `ansible-galaxy collection install -r ansible/requirements.yml` on this machine |
| `make validate-env-vps` | Sanity-check `VPS_*` / `VPS_SSH_*` from `.env` |
| `make bootstrap-jenkins` | Run `bootstrap-vps.sh` (Ansible `vps-bootstrap` playbook) |

## Customization

### **VPS bootstrap**
Use **`.env`** at the repo root (see **`.env.example`**) for `VPS_*`, SSH bootstrap, and optional `ANSIBLE_BECOME_PASS`.

### **Jetson**
Tune defaults in **`ansible/group_vars/jetson_devices.yml`** and role `defaults/` where values are not sensitive. **Secrets and per-device connection** belong in **Jenkins** (see `docs/README.md`), not in `.env`.

### **Tags and Selective Execution**
```bash
cd ansible

# Performance only
ansible-playbook -i inventory/jetson-lan/hosts.yml playbooks/jetson-setup.yml --tags performance

# Network configuration
ansible-playbook -i inventory/jetson-lan/hosts.yml playbooks/jetson-setup.yml --tags network,wifi

# Container platform
ansible-playbook -i inventory/jetson-lan/hosts.yml playbooks/jetson-setup.yml --tags docker,containers
```

## 🛠️ Troubleshooting

### **Connection Issues**
- Verify Jetson IP address and SSH access from the controller that runs Ansible (Jenkins or your shell).
- From `ansible/`: `ansible -i inventory/jetson-lan/hosts.yml jetson -m ping` after exporting `JETSON_*` / SSH settings.
- For SSH keys: align with Jenkins credentials or your local `SSH_PUBLIC_KEY_PATH` when running playbooks by hand.

### **Performance Issues**
- Jetson performance optimization runs first for maximum efficiency
- Check jetson_clocks status: `sudo jetson_clocks --show`
- Verify power mode: `sudo nvpmodel -q`

### **Network Configuration**
- Wi-Fi setup is idempotent - won't disconnect existing connections
- Network fallback service provides automatic recovery
- Check network status: `systemctl status network-fallback.service`

## 📊 Monitoring

### **Network Monitoring**
The system includes automatic network monitoring with failover:
- **Service**: `network-fallback.service`
- **Logs**: `/var/log/network-fallback.log`
- **Status**: `systemctl status network-fallback.service`

### **System Status**
```bash
# Check overall system health
ssh dev@<jetson-ip> "systemctl --failed"

# Verify Docker + NVIDIA runtime
ssh dev@<jetson-ip> "docker run --rm --gpus all nvidia/cuda:11.8-base-ubuntu22.04 nvidia-smi"
```

---

## 📖 Documentation

For more details on creation processes, troubleshooting, and other guidance, visit the [Sentience Robotics documentation](https://docs.sentience-robotics.fr).

---

## 📜 Code of Conduct

We value the participation of each member of our community and are committed to ensuring that every interaction is respectful and productive. To foster a positive environment, we ask you to read and adhere to our [Code of Conduct](CODE_OF_CONDUCT.md).

By participating in this project, you agree to uphold this code in all your interactions, both online and offline. Let's work together to maintain a welcoming and inclusive community for everyone.

If you encounter any issues or have questions regarding the Code of Conduct, please contact us at [contact@sentience-robotics.fr](mailto:contact@sentience-robotics.fr).

Thank you for being a part of our community!

---

## 🤝 Contributing

To find out more on how you can contribute to the project, please check our [CONTRIBUTING.md](CONTRIBUTING.md)

---

## 📜 License

This project is licensed under the **GNU GPL V3 License**. See the [LICENSE](LICENSE) file for details.

---

## 📬 Contact

- 📧 Email: [contact@sentience-robotics.fr](mailto:contact@sentience-robotics.fr)<br>
- 🌍 GitHub Organization: [Sentience Robotics](https://github.com/sentience-robotics)<br>


---

[![Contributor Covenant](https://img.shields.io/badge/Contributor%20Covenant-2.0-4baaaa.svg)](code_of_conduct.md)
