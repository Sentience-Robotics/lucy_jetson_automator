# Job DSL (`jenkins/dsl/*.groovy`)

`lucy-jobs.groovy` is the **source of truth** for the seeded folder **`lucy`** and the two Pipeline-from-SCM jobs:

- `lucy/jetson-config` → `jenkins/pipelines/Jetson.Jenkinsfile`
- `lucy/isaacsim-ovh-lifecycle` → `jenkins/pipelines/IsaacSimOVH.Jenkinsfile`

The Groovy file is **copied into the controller image** at `/usr/share/jenkins/ref/jobdsl/` and synced into `$JENKINS_HOME/jobdsl/` on first boot. **JCasC** (`jenkins/casc/03-jobs-jobdsl.yaml`) evaluates it via `GroovyShell` so Groovy stays reviewable under CODEOWNERS without duplicating logic in YAML.

When changing jobs:

1. Edit `lucy-jobs.groovy` (and pipelines under `jenkins/pipelines/`).
2. Rebuild the Jenkins image / rerun `docker compose up --build`.
3. Confirm CasC reload or restart Jenkins if Job DSL replacement semantics require it.
