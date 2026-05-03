// Source of truth for Job DSL seed jobs (folder lucy + pipelines). Loaded by CasC; do not duplicate logic elsewhere.
def repoUrl = System.getenv('CONTROLLER_REPO_URL') ?: ''
if (!repoUrl?.trim()) {
  println('[lucy-jobdsl] CONTROLLER_REPO_URL empty — set it in jenkins/.env on the VPS')
}

folder('lucy')

pipelineJob('lucy/jetson-config') {
  description('Jetson configure/update over VPN inventory; prod uses immutable GIT_REF (tag or SHA).')
  parameters {
    stringParam('GIT_REF', 'main', 'Immutable git ref (tag or full SHA); avoid unreviewed main for prod')
    stringParam(
      'ANSIBLE_TAGS',
      'jetson,system,network,security,docker,user',
      'ansible-playbook --tags (empty = full playbook — requires approval)'
    )
  }
  definition {
    cpsScm {
      scm {
        git {
          remote {
            url(repoUrl)
          }
          branches('$GIT_REF')
        }
      }
      scriptPath('jenkins/pipelines/Jetson.Jenkinsfile')
      lightweight(false)
    }
  }
}

pipelineJob('lucy/isaacsim-ovh-lifecycle') {
  description('Nova stop/start only for an existing instance; plan archived before gated apply.')
  parameters {
    stringParam('GIT_REF', 'main', 'Immutable git ref (tag or full SHA)')
  }
  definition {
    cpsScm {
      scm {
        git {
          remote {
            url(repoUrl)
          }
          branches('$GIT_REF')
        }
      }
      scriptPath('jenkins/pipelines/IsaacSimOVH.Jenkinsfile')
      lightweight(false)
    }
  }
}
