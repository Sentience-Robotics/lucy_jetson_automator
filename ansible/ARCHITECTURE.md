# Ansible Architecture

## 🎯 **Overview**

The Ansible project follows best practices with improved role organization, clear separation of concerns, and optimized execution order.

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

# Specific phases
ansible-playbook -i inventory/hosts.yml playbooks/jetson-setup.yml --tags jetson,performance
ansible-playbook -i inventory/hosts.yml playbooks/jetson-setup.yml --tags network,wifi
ansible-playbook -i inventory/hosts.yml playbooks/jetson-setup.yml --tags security,ssh
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

## ✅ **Improvements**

### **Better Organization**
- Clear single responsibility per role
- No overlap or duplication (Wi-Fi setup consolidated)
- Logical execution phases

### **Performance Optimized**
- Jetson performance optimization runs FIRST
- All subsequent operations benefit from maximum performance
- Faster package downloads and installations

### **Idempotent Operations**
- Wi-Fi configuration only changes when needed
- Hostname only updated if different
- SSH keys only deployed if missing

### **Enhanced Maintainability**
- Easy to modify individual components
- Clear testing boundaries
- Better error isolation
- Proper role dependencies

### **Improved Reusability**
- Roles can be used independently
- Easy to mix and match for different setups
- Better for CI/CD pipelines

## 🎯 **Benefits Summary**

- **🚀 Faster execution**: Performance optimization first
- **🔧 Better maintenance**: Clear role boundaries
- **🌐 No duplication**: Single Wi-Fi implementation
- **🔐 Enhanced security**: Dedicated security role
- **📦 Modular design**: Independent, reusable roles
- **⚡ Optimized order**: Logical dependency flow

## 🌐 **Advanced Network Features**

### **Parallel WiFi/Ethernet Connections**
- **Simultaneous connections**: Both WiFi and Ethernet active
- **Intelligent failover**: Automatic switching between connections
- **Connection priorities**: Configurable primary interface preference
- **Monitoring service**: Continuous connectivity checking with logging

### **Ethernet Latency Optimization** 
- **Low-latency tuning**: rx-usecs parameter optimization (64μs)
- **Robot manipulator ready**: Based on [NVIDIA Isaac ROS requirements](https://nvidia-isaac-ros.github.io/getting_started/hardware_setup/compute/preempt_setup.html#reduce-ethernet-latency)
- **Automatic detection**: Only applies to existing ethernet interfaces
- **Safe configuration**: Graceful handling of interface conflicts

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

## 👤 **Author Information**
- **Author**: Charles Madjeri
- **Company**: Sentience Robotics
- **License**: MIT