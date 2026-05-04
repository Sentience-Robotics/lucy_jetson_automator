# Job DSL (`jenkins/dsl/*.groovy`)

`lucy-jobs.groovy` is the **source of truth** for the seeded folder **`lucy`** and the two Pipeline-from-SCM jobs:

- `lucy/jetson-config` → `jenkins/pipelines/Jetson.Jenkinsfile` (HTML job description lists required credential IDs and first-time setup steps; Pipeline uses **`agent { label 'docker' }`** — Docker cloud + `lucy-jenkins-agent:local` image)
- `lucy/isaacsim-ovh-lifecycle` → `jenkins/pipelines/IsaacSimOVH.Jenkinsfile`

The Groovy file is **copied into the controller image** at `/usr/share/jenkins/ref/jobdsl/` and synced into `$JENKINS_HOME/jobdsl/` on first boot. **JCasC** (`jenkins/casc/03-jobs-jobdsl.yaml`) loads it with the **`jobs:` → `file:`** Job DSL integration (not raw `GroovyShell.evaluate`, which lacks `folder()` / `pipelineJob()` bindings).

When changing jobs:

1. Edit `lucy-jobs.groovy` (and pipelines under `jenkins/pipelines/`).
2. Rebuild the Jenkins image / rerun `docker compose up --build`.
3. Confirm CasC reload or restart Jenkins if Job DSL replacement semantics require it.
