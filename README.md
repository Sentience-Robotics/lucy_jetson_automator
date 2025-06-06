# NVIDIA Jetson AGX Orin Docker-based Ansible automated setup

Automated Ansible setup for NVIDIA Jetson AGX Orin devices, optimized for robotics development and Isaac ROS deployment.

## 🚀 Quick Start

### 1. **Prerequisites**
- NVIDIA Jetson AGX Orin with JetPack installed
- SSH access to the Jetson
- Docker installed on your host machine

### 2. **Clone and Setup**
```bash
git clone <repository-url>
cd isaac-sim-vps-setup
make init
```

### 3. **Configuration**
Create a `.env` file:
```bash
# Jetson Connection
JETSON_HOST=192.168.0.107
JETSON_USER=dev
JETSON_HOSTNAME=jetson-agx

# Network Configuration  
WIFI_SSID=YourWiFiNetwork
WIFI_PASSWORD=YourWiFiPassword

# SSH Configuration
SSH_PRIVATE_KEY_PATH=id_rsa
SSH_PUBLIC_KEY_PATH=id_rsa.pub

# Isaac ROS (Optional)
SETUP_ISAAC_ROS=false
```

### 4. **Deploy**
```bash
make setup
```

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

## 🌟 Features

### **🚀 Performance Optimized**
- **jetson_clocks** enabled for maximum performance
- **MAXN** power mode configuration
- **CPU governor** optimization
- **Ethernet latency reduction** for robot manipulators (64μs rx-usecs)

### **🌐 Advanced Networking**
- **Parallel WiFi/Ethernet** connections with intelligent failover
- **Network monitoring service** with automatic recovery
- **Connection priorities** and auto-retry configuration
- **Idempotent** network setup (no unnecessary disconnections)

### **🔧 Production Ready**
- **Completely idempotent** - safe to run multiple times
- **Modular roles** - run specific components independently  
- **Smart dependency management** - roles execute in optimal order
- **Comprehensive logging** - detailed setup progress and monitoring

The playbook can automatically deploy your public key if `SSH_PUBLIC_KEY_PATH` is set.

## 📋 Available Commands

### **Main Setup**
```bash
make setup              # Complete optimized setup
make setup-check        # Dry run (check mode)
make ping              # Test connection
```

### **Specialized Setup**
```bash
make setup-performance  # Performance optimization only
make setup-hostname     # Hostname configuration
make setup-wifi        # WiFi configuration
```

### **Utilities**
```bash
make shell             # Interactive Ansible container
make clean             # Clean Docker resources
make help              # Show all commands
```

## 🔧 Customization

### **Environment Variables**
All configuration is done via environment variables in `.env`:

```bash
# Required
JETSON_HOST=<jetson-ip>
JETSON_USER=<username>

# Optional  
JETSON_HOSTNAME=jetson-agx
WIFI_SSID=<network-name>
WIFI_PASSWORD=<password>
SSH_PUBLIC_KEY_PATH=<path-to-public-key>
SETUP_ISAAC_ROS=false
```

### **Role Configuration**
Each role can be configured via variables in `ansible/group_vars/jetson_devices.yml`.

### **Tags and Selective Execution**
```bash
# Performance only
ansible-playbook playbooks/jetson-setup.yml --tags performance

# Network configuration
ansible-playbook playbooks/jetson-setup.yml --tags network,wifi

# Container platform
ansible-playbook playbooks/jetson-setup.yml --tags docker,containers
```

## 🛠️ Troubleshooting

### **Connection Issues**
- Verify Jetson IP address and SSH access
- Check network connectivity: `make ping`
- For SSH keys: ensure public key is properly configured with `SSH_PUBLIC_KEY_PATH`

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

## 🙌 Acknowledgments
<!-- Add, as needed, the peoples, organisation or projects that helped this project -->

- 🎉 [InMoov Project](https://inmoov.fr/) – Original design by Gael Langevin<br>
- 🎉 **All contributors** to the InMoov community<br>

---

## 📬 Contact

- 📧 Email: [contact@sentience-robotics.fr](mailto:contact@sentience-robotics.fr)<br>
- 🌍 GitHub Organization: [Sentience Robotics](https://github.com/sentience-robotics)<br>


---

[![Contributor Covenant](https://img.shields.io/badge/Contributor%20Covenant-2.0-4baaaa.svg)](code_of_conduct.md)
