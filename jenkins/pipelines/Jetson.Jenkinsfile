pipeline {
  agent { label 'docker' }
  options {
    timestamps()
  }
  stages {
    stage('Approve high-impact run') {
      steps {
        script {
          def tags = (params.ANSIBLE_TAGS ?: '').trim()
          def parts = tags ? tags.split(',').collect { it.trim() }.findAll { it } : []
          boolean fullSurface = tags.isEmpty()
          boolean wide = parts.size() > 6
          def hazardous = ['jetson-optimization', 'performance', 'isaac-ros-platform']
          boolean touchesHazard = parts.any { hazardous.contains(it) }
          if (fullSurface || wide || touchesHazard) {
            input message: 'High-impact Ansible run (full playbook, wide tag surface, or jetson-optimization / performance / isaac-ros-platform). Confirm to proceed.'
          }
        }
      }
    }
    stage('Ansible apply') {
      steps {
        withCredentials([
          string(credentialsId: 'jetson-host', variable: 'JETSON_HOST'),
          sshUserPrivateKey(credentialsId: 'jetson-ssh-key', keyFileVariable: 'SSH_PRIVATE_KEY_FILE', usernameVariable: 'JETSON_USER'),
          string(credentialsId: 'jetson-password', variable: 'JETSON_PASSWORD'),
          string(credentialsId: 'jetson-hostname', variable: 'JETSON_HOSTNAME'),
          string(credentialsId: 'jetson-wifi-ssid', variable: 'WIFI_SSID'),
          string(credentialsId: 'jetson-wifi-password', variable: 'WIFI_PASSWORD'),
          string(credentialsId: 'jetson-jetpack-version', variable: 'JETSON_JETPACK_VERSION')
        ]) {
          script {
            def isaac = (params.get('SETUP_ISAAC_ROS')?.toString() == 'true') ? 'true' : 'false'
            sh """
            set -eu
            export ANSIBLE_CONFIG="\${WORKSPACE}/ansible/ansible.cfg"
            export USE_SSH_KEY_AUTH=true
            export SSH_PUBLIC_KEY_PATH=/nonexistent
            export ANSIBLE_BECOME_PASS="\${JETSON_PASSWORD}"
            export SETUP_ISAAC_ROS=${isaac}
            cd ansible
            TAGS="\${ANSIBLE_TAGS:-}"
            if [ -n "\$TAGS" ]; then
              ansible-playbook -i inventory/jetson-vpn/hosts.yml \\
                --private-key "\${SSH_PRIVATE_KEY_FILE}" -u "\${JETSON_USER}" \\
                playbooks/jetson-setup.yml --tags "\$TAGS" -v
            else
              ansible-playbook -i inventory/jetson-vpn/hosts.yml \\
                --private-key "\${SSH_PRIVATE_KEY_FILE}" -u "\${JETSON_USER}" \\
                playbooks/jetson-setup.yml -v
            fi
            """
          }
        }
      }
    }
  }
}
