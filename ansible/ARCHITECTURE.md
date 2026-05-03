# Ansible Architecture
## 🎯 **Overview**

The Ansible layout splits **Jetson edge provisioning** from **VPS tier‑0 controller bootstrap**:

| Track | Inventory | Entry playbook |
|-------|-----------|----------------|
| Jetson (LAN lab) | `inventory/jetson-lan/` | `playbooks/jetson-setup.yml` |
| Jetson over VPN | `inventory/jetson-vpn/` | same playbook — Jenkins/agents should prefer VPN hosts |
| VPS localhost bootstrap | `inventory/vps-bootstrap/` | `playbooks/vps-bootstrap.yml` (Docker, UFW, Jenkins Compose) |

Shared vars live under `group_vars/`; Jetson‑specific sudo/password overrides belong in `group_vars/jetson_devices.yml`, not forced globally on localhost/VPS.

## 🏗️ **Role Structure**

### **Execution Order** (Optimized for Performance)

1. **`jetson-optimization`** ⚡ - Performance optimization (FIRST PRIORITY)
2. **`system-foundation`** 🏗️ - Core system updates and packages  
3. **`network-configuration`** 🌐 - Hostname and Wi-Fi setup
4. **`security-hardening`** 🔐 - SSH keys and access control
5. **`container-platform`** 🐳 - Docker and NVIDIA runtime
6. **`isaac-ros-platform`** 🤖 - Isaac ROS specific setup (optional)
7. **`user-environment`** 👤 - Shell and development tools

## 📋 **Role Responsibilities**

### **jetson-optimization** ⚡
- Enable jetson_clocks for maximum performance
- Set MAXN power mode
- Configure CPU/GPU governors
- Optimize thermal management
- **NEW**: Ethernet latency optimization (rx-usecs tuning for robot manipulators)
- **Why first**: Ensures all subsequent operations run at peak performance

### **system-foundation** 🏗️
- Update package repositories and system packages
- Install essential utilities (curl, wget, vim, git, etc.)
- Handle apt lock management and retries
- Check reboot requirements

### **network-configuration** 🌐
- Configure system hostname (idempotent)
- Set up Wi-Fi connections (idempotent, consolidated from multiple roles)
- **NEW**: Ethernet interface monitoring and configuration
- **NEW**: Parallel WiFi/Ethernet connections with intelligent fallback
- **NEW**: Network monitoring service with automatic failover
- Install and configure NetworkManager
- **Eliminates duplication**: Single source for all network configuration

### **security-hardening** 🔐
- Deploy SSH public keys
- Configure SSH access and permissions
- Set up secure access controls
- Maintain Jetson compatibility

### **container-platform** 🐳
- Install Docker Engine and components
- Configure NVIDIA Container Runtime
- Set up Docker Buildx and Compose
- Add user to docker group

### **isaac-ros-platform** 🤖
- Isaac ROS specific dependencies
- ROS 2 workspace configuration
- Isaac ROS environment setup
- **Optional**: Can be skipped with `setup_isaac_ros: false`

### **user-environment** 👤
- Install and configure zsh + oh-my-zsh
- Set up development tools and aliases
- Configure shell environment
- **Last**: User customization after platform is ready

## 🚀 **Usage**

### **Setup Commands**
```bash
# Complete setup with optimized architecture
make setup

# Performance optimization only
make setup-performance

# Specific phases (run from ansible/)
ansible-playbook -i inventory/jetson-lan/hosts.yml playbooks/jetson-setup.yml --tags jetson,performance
ansible-playbook -i inventory/jetson-lan/hosts.yml playbooks/jetson-setup.yml --tags network,wifi
ansible-playbook -i inventory/jetson-lan/hosts.yml playbooks/jetson-setup.yml --tags security,ssh
```

### **Specialized Commands**
```bash
# Hostname configuration
make setup-hostname

# WiFi configuration  
make setup-wifi

# Dry run
make setup-check
```

### **Network Configuration Options**
```yaml
# Environment variables
WIFI_SSID=YourNetwork
WIFI_PASSWORD=yourpassword

# Role defaults
network_strategy:
  connection_mode: "parallel"  # 'parallel', 'wifi_primary', 'ethernet_primary'
  enable_fallback: true
  primary_interface_preference: "ethernet"  # 'ethernet' or 'wifi'
```

## 📊 **Monitoring and Logging**
- **Network status**: Real-time connection monitoring
- **Fallback events**: Logged to `/var/log/network-fallback.log`
- **Systemd service**: `network-fallback.service` for reliable operation
- **Health checks**: Connectivity testing via ping to external servers
