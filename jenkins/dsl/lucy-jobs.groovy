// Source of truth for Job DSL seed jobs (folder lucy + pipelines). Loaded by CasC; do not duplicate logic elsewhere.
def repoUrl = System.getenv('CONTROLLER_REPO_URL') ?: ''
if (!repoUrl?.trim()) {
  println('[lucy-jobdsl] CONTROLLER_REPO_URL empty — set it in jenkins/.env on the VPS')
}

def jetsonJobDescription = '''
<h2>First-time setup (secrets only in Jenkins)</h2>
<ol>
  <li>Open <b>Manage Jenkins → Credentials</b> (folder-scoped store for <code>lucy</code> recommended).</li>
  <li>Add each item below with the <b>exact credential ID</b>. Jenkins encrypts secrets at rest.</li>
  <li>Return here and use <b>Build with Parameters</b> (set <code>GIT_REF</code>, tags, Isaac ROS as needed).</li>
</ol>
<h2>Required credential IDs</h2>
<ul>
  <li><code>jetson-host</code> — <i>Secret text</i>: Jetson <code>ansible_host</code> (VPN DNS or IP).</li>
  <li><code>jetson-ssh-key</code> — <i>SSH Username with private key</i>: SSH user + private key for the device.</li>
  <li><code>jetson-password</code> — <i>Secret text</i>: sudo / Ansible become password.</li>
  <li><code>jetson-hostname</code> — <i>Secret text</i> (optional): <code>JETSON_HOSTNAME</code>.</li>
  <li><code>jetson-wifi-ssid</code> — <i>Secret text</i> (optional).</li>
  <li><code>jetson-wifi-password</code> — <i>Secret text</i> (optional).</li>
  <li><code>jetson-jetpack-version</code> — <i>Secret text</i> (e.g. <code>6.2</code>).</li>
</ul>
<p>Repository reference: <code>docs/README.md</code> (credential table). This job injects the IDs above via <code>withCredentials</code>; nothing equivalent belongs in Git <code>.env</code>.</p>
'''.stripIndent()

folder('lucy') {
  description('<p>Lucy tier-0 automation. Jetson connection secrets live in <b>Jenkins credentials</b> only.</p>')
}

pipelineJob('lucy/jetson-config') {
  description(jetsonJobDescription)
  parameters {
    stringParam('GIT_REF', 'main', 'Immutable git ref (tag or full SHA); avoid unreviewed main for prod')
    stringParam(
      'ANSIBLE_TAGS',
      'jetson,system,network,security,docker,user',
      'ansible-playbook --tags (empty = full playbook — requires approval)'
    )
    booleanParam('SETUP_ISAAC_ROS', false, 'If true, run Isaac ROS installation tasks (optional)')
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
    stringParam('SERVER_ID', '', 'OpenStack server UUID (nova)')
    stringParam('OS_CLOUD_NAME', 'openstack', 'Cloud entry name inside clouds.yaml')
    choiceParam('DESIRED_POWER', ['running', 'stopped'], 'Target power state (Nova stop/start)')
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
