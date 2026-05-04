pipeline {
  agent { label 'docker' }
  options {
    timestamps()
  }
  // Parameters are defined in Job DSL (lucy-jobs.groovy) so "Build with Parameters" lists GIT_REF + OVH fields together before checkout.
  stages {
    stage('Validate parameters') {
      steps {
        script {
          if (!params.SERVER_ID?.trim()) {
            error('SERVER_ID is required (Nova server UUID)')
          }
          if (params.GIT_REF == 'main') {
            echo 'WARNING: GIT_REF is main — prefer an immutable tag or SHA for production Isaac Sim runs.'
          }
        }
      }
    }
    stage('Terraform init') {
      steps {
        withCredentials([
          file(credentialsId: 'openstack-clouds-yaml', variable: 'OS_CLIENT_CONFIG_FILE')
        ]) {
          dir('terraform/ovh-instance-lifecycle') {
            sh '''
              set -eu
              terraform init -input=false
            '''
          }
        }
      }
    }
    stage('Terraform plan') {
      steps {
        withCredentials([
          file(credentialsId: 'openstack-clouds-yaml', variable: 'OS_CLIENT_CONFIG_FILE')
        ]) {
          dir('terraform/ovh-instance-lifecycle') {
            sh '''
              set -eu
              terraform plan -input=false -out=tfplan \
                -var "desired_power=${DESIRED_POWER}" \
                -var "server_id=${SERVER_ID}" \
                -var "cloud_name=${OS_CLOUD_NAME}"
              terraform show -no-color tfplan | tee tf-plan.txt
            '''
          }
        }
      }
    }
    stage('Archive plan') {
      steps {
        dir('terraform/ovh-instance-lifecycle') {
          archiveArtifacts artifacts: 'tf-plan.txt', fingerprint: true
          archiveArtifacts artifacts: 'tfplan', fingerprint: true
        }
      }
    }
    stage('Approve apply') {
      steps {
        input message: 'Apply Terraform plan to change OpenStack power state?'
      }
    }
    stage('Terraform apply') {
      steps {
        withCredentials([
          file(credentialsId: 'openstack-clouds-yaml', variable: 'OS_CLIENT_CONFIG_FILE')
        ]) {
          dir('terraform/ovh-instance-lifecycle') {
            sh '''
              set -eu
              terraform apply -input=false tfplan
            '''
          }
        }
      }
    }
  }
}
