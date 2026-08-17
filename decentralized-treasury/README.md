# decentralized-treasury

![Version: 0.1.0](https://img.shields.io/badge/Version-0.1.0-informational?style=flat-square) ![Type: application](https://img.shields.io/badge/Type-application-informational?style=flat-square) ![AppVersion: 0.1.0](https://img.shields.io/badge/AppVersion-0.1.0-informational?style=flat-square)

A Helm chart for deploying the Mina Decentralized Treasury stack (API, indexer, processor, schedulers, web and proving services)

**Homepage:** <https://minaprotocol.com/>

## Requirements

| Repository | Name | Version |
|------------|------|---------|
| https://charts.bitnami.com/bitnami | postgresql | 15.2.9 |

## Prerequisites

Before using this Helm chart, you should have the following prerequisites:

- Access to Kubernetes cluster (If needed contact your friendly neighbourhood DevOps engineer)
- Helm >= v3.14.3
- (**Optional**) helmfile >= v0.162.0 to install this chart

## Installation

> Note: **examples** can be found in the repository

To install this Helm chart, the easiest is to create a helmfile.yaml with needed values and run:

```
helmfile template
helmfile apply
```

Or use helmfile only to generate resources and apply them with kubectl like so:

```
helmfile template | kubectl -f -
```

Verify that the chart is deployed successfully:

> Note: `kubectl` is a better suited tool for this

```
helmfile status
```

## Values

| Key | Type | Default | Description |
|-----|------|---------|-------------|
| affinity | object | `{}` | Affinity for pod assignment |
| api | object | `{"deploymentAnnotations":{},"enabled":true,"extraEnvVars":[],"image":{"pullPolicy":"","repository":"minafoundation/dt-api","tag":""},"livenessProbe":{"failureThreshold":3,"httpGet":{"path":"/healthz","port":"http"},"initialDelaySeconds":15,"periodSeconds":20,"timeoutSeconds":5},"podAnnotations":{},"port":4000,"readinessProbe":{"failureThreshold":3,"httpGet":{"path":"/healthz","port":"http"},"initialDelaySeconds":5,"periodSeconds":10,"timeoutSeconds":5},"replicaCount":1,"resources":{},"service":{"annotations":{},"port":4000,"type":"ClusterIP"},"sqlite":{"enabled":true,"keepLastN":0}}` | Public treasury HTTP API (apps/api start:api). Reads proposal state from Postgres and lifecycle witnesses from the SQLite cache. |
| api.deploymentAnnotations | object | `{}` | Annotations to add to the deployment |
| api.enabled | bool | `true` | Whether to deploy the API |
| api.extraEnvVars | list | `[]` | Additional environment variables |
| api.image.pullPolicy | string | `""` | Overrides the chart-wide pull policy |
| api.image.repository | string | `"minafoundation/dt-api"` | The image repository |
| api.image.tag | string | `""` | Overrides the chart-wide tag |
| api.livenessProbe | object | `{"failureThreshold":3,"httpGet":{"path":"/healthz","port":"http"},"initialDelaySeconds":15,"periodSeconds":20,"timeoutSeconds":5}` | Liveness probe. /healthz returns a static OK and checks neither the database nor the SQLite cache. |
| api.podAnnotations | object | `{}` | Annotations to add to the pods |
| api.port | int | `4000` | Port the container listens on |
| api.readinessProbe | object | `{"failureThreshold":3,"httpGet":{"path":"/healthz","port":"http"},"initialDelaySeconds":5,"periodSeconds":10,"timeoutSeconds":5}` | Readiness probe |
| api.replicaCount | int | `1` | Replica count. Stateless and safe to scale horizontally; each replica keeps its own copy of the SQLite cache. |
| api.resources | object | `{}` | The Resources |
| api.service.annotations | object | `{}` | Annotations to add to the service |
| api.service.port | int | `4000` | The service port |
| api.service.type | string | `"ClusterIP"` | The service type |
| api.sqlite.enabled | bool | `true` | Mirror the lifecycle SQLite cache from S3 into this pod. Disable only if the witness and voting-ledger endpoints are not needed. |
| api.sqlite.keepLastN | int | `0` | Number of most recent lifecycle bodies to keep locally; 0 keeps all. Safe to bound here because the API turns a missing lifecycle into a structured LIFECYCLE_DATA_UNAVAILABLE_ERROR, unlike the processor. Requests for older lifecycles will fail with that error. |
| apiDirectory | string | `"/app/apps/api"` | Path to the api workspace inside the image. The wait-for-* scripts resolve the `pg` package and the shipped migration files relative to this. |
| apiMigrate | object | `{"annotations":{},"backoffLimit":6,"enabled":true,"extraEnvVars":[],"image":{"pullPolicy":"","repository":"minafoundation/dt-api-migrate","tag":""},"podAnnotations":{},"rerunPolicy":"revision","resources":{},"ttlSecondsAfterFinished":600,"waitTimeoutSeconds":600}` | Schema migrations, run as a plain Job rather than a Helm hook. |
| apiMigrate.annotations | object | `{}` | Annotations to add to the Job |
| apiMigrate.backoffLimit | int | `6` | Number of retries before the Job is marked failed |
| apiMigrate.enabled | bool | `true` | Whether to run schema migrations |
| apiMigrate.extraEnvVars | list | `[]` | Additional environment variables for the migration container |
| apiMigrate.image.pullPolicy | string | `""` | Overrides the chart-wide pull policy |
| apiMigrate.image.repository | string | `"minafoundation/dt-api-migrate"` | The image repository |
| apiMigrate.image.tag | string | `""` | Overrides the chart-wide tag |
| apiMigrate.podAnnotations | object | `{}` | Annotations to add to the Job pod |
| apiMigrate.rerunPolicy | string | `"revision"` | What makes the Job run again. Job pod specs are immutable, so migrations only re-run when the Job name changes.   revision - a new Job on every helm upgrade. Required with a mutable tag              such as `latest`, where keying on the tag would mean the Job              never changes and migrations silently stop running.   tag      - a new Job only when the image tag changes. Only correct if you              publish immutable tags. |
| apiMigrate.resources | object | `{}` | The Resources |
| apiMigrate.ttlSecondsAfterFinished | int | `600` | How long a finished Job is retained before it is garbage collected |
| apiMigrate.waitTimeoutSeconds | int | `600` | How long the init container waits for Postgres to accept connections |
| config.apiPageLimitDefault | int | `50` | Default page size for list endpoints |
| config.apiPageLimitMax | int | `200` | Maximum page size for list endpoints |
| config.apiUrl | string | `""` | Override the in-cluster URL of api. Empty derives it from the Service. |
| config.archiveNodeUrl | string | `"http://devops.hz.minaprotocol.network:8080"` | Archive node GraphQL endpoint. Defaults to the shared devops archive node; point this at an in-cluster archive (e.g. http://mina-archive:8282) when the release has one of its own. |
| config.archiveRequestTimeoutMs | int | `15000` | Timeout for archive node requests, in milliseconds |
| config.corsAllowedOrigins | list | `[]` | Origins allowed to call the HTTP APIs. Empty keeps the application default. |
| config.indexerApiUrl | string | `""` | Override the in-cluster URL of indexer-api. Empty derives it from the Service. |
| config.lifecyclePeriodDuration | int | `7140` | Slots in one lifecycle period. Required by voting-ledger-scheduler. |
| config.processorApiUrl | string | `""` | Override the in-cluster URL of processor-api. Empty derives it from the Service. |
| config.processorName | string | `""` | Processor identity, used as the key for stored processor offsets. Shared by processor and processor-api, which must agree or the API reports on a different processor's progress. Empty keeps the application default. |
| config.proofsEnabled | bool | `false` | Whether the stack produces real proofs |
| config.proposalContentMaxChars | string | `""` | Maximum proposal content length in characters. Empty keeps the application default (32768). |
| config.treasuryDeployedAtSlot | int | `0` | Slot at which the treasury contract was deployed. Lifecycle ids are counted from here, which is why they differ per network. |
| config.treasuryOwnerContractAddress | string | `"B62qpExe8CAaGkR4HRxyXvkziQpE6Aq3U71MJLHivP8pCsiDk1BbU9Z"` | Treasury owner zkApp address. Network-specific: pointing this at an address from another network yields a service that indexes nothing at all rather than erroring, so set it deliberately per network. |
| database.existingSecret | string | `""` | Use an existing Secret holding the connection URL instead of rendering one from the values above. Recommended in production, and required if the password contains characters that do not survive URL assembly. |
| database.existingSecretUrlKey | string | `"database-url"` | Key within the Secret that holds the full `postgres://` URL |
| database.schema | string | `"public"` | Postgres schema the api workspace reads and migrates |
| externalDatabase | object | `{"database":"treasury_api","enabled":false,"host":"","password":"","port":5432,"username":"treasury"}` | An already-running Postgres to use instead of the bundled subchart. |
| externalDatabase.database | string | `"treasury_api"` | Database name for external database connection |
| externalDatabase.enabled | bool | `false` | Use an existing external database server, ignoring the bundled subchart |
| externalDatabase.host | string | `""` | Host for external database connection |
| externalDatabase.password | string | `""` | Password for external database connection |
| externalDatabase.port | int | `5432` | Port for external database connection |
| externalDatabase.username | string | `"treasury"` | Username for external database connection |
| extraObjects | list | `[]` | Extra Kubernetes objects to deploy |
| fullnameOverride | string | `""` | The full release name override |
| image.pullPolicy | string | `"IfNotPresent"` | Pull policy applied to every component image unless it overrides it |
| image.tag | string | `"latest"` | Tag applied to every component image unless it overrides it |
| imagePullSecrets | list | `[]` | The secrets used to pull the image |
| indexer | object | `{"canonicalOverlapBlocks":"","deploymentAnnotations":{},"enabled":true,"eventsBlockBatchSize":"","extraEnvVars":[],"image":{"pullPolicy":"","repository":"minafoundation/dt-indexer","tag":""},"orphanDepthBlocks":"","pendingOverlapBlocks":"","podAnnotations":{},"pollCanonicalIntervalMs":15000,"pollPendingIntervalMs":5000,"replicaCount":1,"resources":{}}` | Archive event indexer worker (apps/api start:indexer). No HTTP server and no Service; its progress is observable through indexer-api's status routes. |
| indexer.canonicalOverlapBlocks | string | `""` | Blocks re-scanned behind the canonical cursor. Empty keeps the default (100). |
| indexer.deploymentAnnotations | object | `{}` | Annotations to add to the deployment |
| indexer.enabled | bool | `true` | Whether to deploy the indexer worker |
| indexer.eventsBlockBatchSize | string | `""` | Blocks fetched per archive request. Empty keeps the application default (10). |
| indexer.extraEnvVars | list | `[]` | Additional environment variables |
| indexer.image.pullPolicy | string | `""` | Overrides the chart-wide pull policy |
| indexer.image.repository | string | `"minafoundation/dt-indexer"` | The image repository |
| indexer.image.tag | string | `""` | Overrides the chart-wide tag |
| indexer.orphanDepthBlocks | string | `""` | Depth at which forks are treated as orphaned. Empty keeps the default (30). |
| indexer.pendingOverlapBlocks | string | `""` | Blocks re-scanned behind the pending cursor. Empty keeps the default (20). |
| indexer.podAnnotations | object | `{}` | Annotations to add to the pods |
| indexer.pollCanonicalIntervalMs | int | `15000` | How often to poll for canonical blocks, in milliseconds |
| indexer.pollPendingIntervalMs | int | `5000` | How often to poll for pending blocks, in milliseconds |
| indexer.replicaCount | int | `1` | Replica count. Must stay 1 — the archive cursor is a blind upsert with no lock or leader election, so a second replica can rewind indexing progress. The template refuses to render any other value. |
| indexer.resources | object | `{}` | The Resources |
| indexerApi | object | `{"deploymentAnnotations":{},"enabled":true,"extraEnvVars":[],"image":{"pullPolicy":"","repository":"minafoundation/dt-indexer-api","tag":""},"livenessProbe":{"failureThreshold":3,"httpGet":{"path":"/healthz","port":"http"},"initialDelaySeconds":15,"periodSeconds":20,"timeoutSeconds":5},"podAnnotations":{},"port":4001,"readinessProbe":{"failureThreshold":3,"httpGet":{"path":"/healthz","port":"http"},"initialDelaySeconds":5,"periodSeconds":10,"timeoutSeconds":5},"replicaCount":1,"resources":{},"service":{"annotations":{},"port":4001,"type":"ClusterIP"}}` | Read-only HTTP API over indexed archive events (apps/api start:indexer-api). |
| indexerApi.deploymentAnnotations | object | `{}` | Annotations to add to the deployment |
| indexerApi.enabled | bool | `true` | Whether to deploy the indexer API |
| indexerApi.extraEnvVars | list | `[]` | Additional environment variables |
| indexerApi.image.pullPolicy | string | `""` | Overrides the chart-wide pull policy |
| indexerApi.image.repository | string | `"minafoundation/dt-indexer-api"` | The image repository |
| indexerApi.image.tag | string | `""` | Overrides the chart-wide tag |
| indexerApi.livenessProbe | object | `{"failureThreshold":3,"httpGet":{"path":"/healthz","port":"http"},"initialDelaySeconds":15,"periodSeconds":20,"timeoutSeconds":5}` | Liveness probe. /healthz returns a static OK and does not check the database, so it detects a hung process but not a broken dependency. |
| indexerApi.podAnnotations | object | `{}` | Annotations to add to the pods |
| indexerApi.port | int | `4001` | Port the container listens on |
| indexerApi.readinessProbe | object | `{"failureThreshold":3,"httpGet":{"path":"/healthz","port":"http"},"initialDelaySeconds":5,"periodSeconds":10,"timeoutSeconds":5}` | Readiness probe |
| indexerApi.replicaCount | int | `1` | Replica count. Stateless and safe to scale horizontally. |
| indexerApi.resources | object | `{}` | The Resources |
| indexerApi.service.annotations | object | `{}` | Annotations to add to the service |
| indexerApi.service.port | int | `4001` | The service port |
| indexerApi.service.type | string | `"ClusterIP"` | The service type |
| ingress | object | `{"annotations":{},"apiAnnotations":{"nginx.ingress.kubernetes.io/rewrite-target":"/$2"},"apiPathPrefix":"","className":"nginx","enabled":false,"extraPaths":[],"host":"","hosts":{"api":"","indexer":"","processor":""},"mode":"path","tls":[]}` | Ingress, replacing the Caddy reverse-proxy services from compose. Renders two objects: one for web and one for the API paths, which need a prefix rewrite that must not apply to web. |
| ingress.annotations | object | `{}` | Annotations for the web Ingress |
| ingress.apiAnnotations | object | `{"nginx.ingress.kubernetes.io/rewrite-target":"/$2"}` | Annotations for the API Ingress. The rewrite is what reproduces Caddy's `handle_path`, which strips the prefix before proxying — the APIs serve their routes at the root. Adjust if you use a controller other than nginx. |
| ingress.apiPathPrefix | string | `""` | Optional prefix in front of /api, /indexer and /processor |
| ingress.className | string | `"nginx"` | Ingress class name |
| ingress.enabled | bool | `false` | Enable Ingress |
| ingress.extraPaths | list | `[]` | Extra paths appended to the web Ingress. Use this for the Mina node GraphQL route the Caddyfile proxied at /mina, pointing at whatever Service fronts your node. |
| ingress.host | string | `""` | Hostname the web app is served on. Required when enabled. |
| ingress.hosts | object | `{"api":"","indexer":"","processor":""}` | Per-service hostnames, used only when mode is `host`. Any left empty is simply not exposed. |
| ingress.mode | string | `"path"` | Routing mode.   path  - one hostname, with /api, /indexer and /processor stripped before           proxying (needs a rewrite annotation; works on nginx).   host  - a separate hostname per service and no rewriting. Use this on ALB:           the AWS Load Balancer Controller has no rewrite-target equivalent,           so path mode cannot strip the prefix and the APIs would 404.   proxy - one hostname routed to the in-cluster proxy, which does the           stripping itself. Also for ALB, and the only one of the two that           works with a web image built against same-origin paths, since           those URLs are baked into the client bundle at build time.           Requires proxy.enabled. |
| ingress.tls | list | `[]` | TLS configuration, e.g. from cert-manager |
| migrationWait | object | `{"enabled":true,"pollIntervalSeconds":5,"resources":{},"timeoutSeconds":600}` | Init container that blocks a workload until the schema is migrated. Added to every workload that reads the database, so they can all be applied alongside the migration Job and still converge in the right order. |
| migrationWait.enabled | bool | `true` | Whether dependent workloads wait for migrations before starting |
| migrationWait.pollIntervalSeconds | int | `5` | How often to re-check whether migrations have been applied |
| migrationWait.resources | object | `{}` | The Resources |
| migrationWait.timeoutSeconds | int | `600` | How long to wait before the init container gives up and fails the pod |
| nameOverride | string | `""` | The release name override |
| network | string | `"singlenet"` | Mina network this release targets. Doubles as the S3 key prefix, which is what keeps lifecycle ids from colliding between networks: a lifecycle id is a small integer counted from TREASURY_DEPLOYED_AT_SLOT, so singlenet and mainnet both start at 0. |
| nodeSelector | object | `{}` | Node selector labels |
| podLabels | object | `{}` | Label to add to the pods |
| podSecurityContext | object | `{"fsGroup":1000}` | The Pod Security Context. fsGroup makes the shared SQLite cache writable by both the application container (which runs as the image's `node` user, uid 1000) and the aws-cli sync sidecar. |
| postgresql | object | `{"auth":{"database":"treasury_api","password":"","username":"treasury"},"enabled":true,"primary":{"persistence":{"enabled":true,"size":"8Gi","storageClass":""},"service":{"ports":{"postgresql":5432}}}}` | Bundled Postgres, deployed as a subchart. |
| postgresql.auth.database | string | `"treasury_api"` | Name of the database to create |
| postgresql.auth.password | string | `""` | Password for the database |
| postgresql.auth.username | string | `"treasury"` | Username for the database |
| postgresql.enabled | bool | `true` | Enable the bundled postgresql database server |
| postgresql.primary.persistence.enabled | bool | `true` | Enable persistence for the postgresql server |
| postgresql.primary.persistence.size | string | `"8Gi"` | Size of the postgresql server volume |
| postgresql.primary.persistence.storageClass | string | `""` | Storage class for the postgresql server volume |
| postgresql.primary.service.ports.postgresql | int | `5432` | Port the database server listens on |
| processor | object | `{"batchSize":"","deploymentAnnotations":{},"enabled":true,"extraEnvVars":[],"image":{"pullPolicy":"","repository":"minafoundation/dt-processor","tag":""},"podAnnotations":{},"pollIntervalMs":"","replicaCount":1,"resources":{},"sqlite":{"enabled":true,"keepLastN":0}}` | Event processor worker (apps/api start:processor). Consumes events from indexer-api and writes proposal state to Postgres. |
| processor.batchSize | string | `""` | Events fetched per batch. Empty keeps the application default (200). |
| processor.deploymentAnnotations | object | `{}` | Annotations to add to the deployment |
| processor.enabled | bool | `true` | Whether to deploy the processor |
| processor.extraEnvVars | list | `[]` | Additional environment variables |
| processor.image.pullPolicy | string | `""` | Overrides the chart-wide pull policy |
| processor.image.repository | string | `"minafoundation/dt-processor"` | The image repository |
| processor.image.tag | string | `""` | Overrides the chart-wide tag |
| processor.podAnnotations | object | `{}` | Annotations to add to the pods |
| processor.pollIntervalMs | string | `""` | How often to poll for new events, in milliseconds. Empty keeps the application default (2000). |
| processor.replicaCount | int | `1` | Replica count. Must stay 1 — the stored offset takes no lock and the vote handlers apply deltas, so a second replica would double-count votes. The template refuses to render any other value. |
| processor.resources | object | `{}` | The Resources |
| processor.sqlite.enabled | bool | `true` | Mirror the lifecycle SQLite cache from S3 into this pod |
| processor.sqlite.keepLastN | int | `0` | Number of recent lifecycle bodies to keep; 0 keeps all.  Leave this at 0. This workload walks a backlog from a stored offset, so it can need any lifecycle, and a missing voting ledger is not graceful here: the handler throws, the offset is not advanced, and the same batch retries every poll interval indefinitely. The process stays up and healthy-looking while indexing has silently stopped. |
| processorApi | object | `{"deploymentAnnotations":{},"enabled":true,"extraEnvVars":[],"image":{"pullPolicy":"","repository":"minafoundation/dt-processor-api","tag":""},"livenessProbe":{"failureThreshold":3,"httpGet":{"path":"/healthz","port":"http"},"initialDelaySeconds":15,"periodSeconds":20,"timeoutSeconds":5},"podAnnotations":{},"port":4002,"readinessProbe":{"failureThreshold":3,"httpGet":{"path":"/healthz","port":"http"},"initialDelaySeconds":5,"periodSeconds":10,"timeoutSeconds":5},"replicaCount":1,"resources":{},"service":{"annotations":{},"port":4002,"type":"ClusterIP"}}` | Read/write HTTP API over processed proposal state (apps/api start:processor-api). |
| processorApi.deploymentAnnotations | object | `{}` | Annotations to add to the deployment |
| processorApi.enabled | bool | `true` | Whether to deploy the processor API |
| processorApi.extraEnvVars | list | `[]` | Additional environment variables |
| processorApi.image.pullPolicy | string | `""` | Overrides the chart-wide pull policy |
| processorApi.image.repository | string | `"minafoundation/dt-processor-api"` | The image repository |
| processorApi.image.tag | string | `""` | Overrides the chart-wide tag |
| processorApi.livenessProbe | object | `{"failureThreshold":3,"httpGet":{"path":"/healthz","port":"http"},"initialDelaySeconds":15,"periodSeconds":20,"timeoutSeconds":5}` | Liveness probe. /healthz returns a static OK and does not check the database, so it detects a hung process but not a broken dependency. |
| processorApi.podAnnotations | object | `{}` | Annotations to add to the pods |
| processorApi.port | int | `4002` | Port the container listens on |
| processorApi.readinessProbe | object | `{"failureThreshold":3,"httpGet":{"path":"/healthz","port":"http"},"initialDelaySeconds":5,"periodSeconds":10,"timeoutSeconds":5}` | Readiness probe |
| processorApi.replicaCount | int | `1` | Replica count. Stateless and safe to scale horizontally. |
| processorApi.resources | object | `{}` | The Resources |
| processorApi.service.annotations | object | `{}` | Annotations to add to the service |
| processorApi.service.port | int | `4002` | The service port |
| processorApi.service.type | string | `"ClusterIP"` | The service type |
| proving | object | `{"enabled":false,"queueName":"staking-ledger-to-voting-ledger","redis":{"enabled":true,"externalHost":"","image":{"pullPolicy":"IfNotPresent","repository":"redis","tag":"7-alpine"},"port":6379,"resources":{},"securityContext":{"allowPrivilegeEscalation":false,"capabilities":{"drop":["ALL"]}}},"scheduler":{"deploymentAnnotations":{},"enabled":true,"extraEnvVars":[],"image":{"pullPolicy":"","repository":"minafoundation/dt-proving-scheduler","tag":""},"outputDirectory":"/data/proofs","outputSizeLimit":"","podAnnotations":{},"pollIntervalSeconds":30,"replicaCount":1,"resources":{},"sqlite":{"keepLastN":0}},"worker":{"affinity":{},"autoscale":{"enabled":false,"maxReplicas":"","minReplicas":0,"pollIntervalSeconds":15,"resources":{},"scaleDownAfterSeconds":180},"cacheSizeLimit":"","deploymentAnnotations":{},"enabled":true,"extraEnvVars":[],"image":{"pullPolicy":"","repository":"minafoundation/dt-proving-worker","tag":""},"nodeSelector":{},"podAnnotations":{},"proofsEnabled":true,"replicaCount":3,"resources":{},"tolerations":[]}}` | Proof generation, matching the compose `proving` profile. Off by default. |
| proving.enabled | bool | `false` | Whether to deploy any proving workload |
| proving.queueName | string | `"staking-ledger-to-voting-ledger"` | BullMQ queue shared by the scheduler and the workers |
| proving.redis.enabled | bool | `true` | Deploy redis as part of this chart |
| proving.redis.externalHost | string | `""` | Use an existing redis instead. Set to a hostname to skip the bundled one. |
| proving.redis.port | int | `6379` | Redis port |
| proving.redis.resources | object | `{}` | The Resources |
| proving.redis.securityContext | object | `{"allowPrivilegeEscalation":false,"capabilities":{"drop":["ALL"]}}` | The Security Context |
| proving.scheduler.deploymentAnnotations | object | `{}` | Annotations to add to the deployment |
| proving.scheduler.enabled | bool | `true` | Whether to deploy the proving scheduler |
| proving.scheduler.extraEnvVars | list | `[]` | Additional environment variables |
| proving.scheduler.image.pullPolicy | string | `""` | Overrides the chart-wide pull policy |
| proving.scheduler.image.repository | string | `"minafoundation/dt-proving-scheduler"` | The image repository. NOTE: not published yet. |
| proving.scheduler.image.tag | string | `""` | Overrides the chart-wide tag |
| proving.scheduler.outputDirectory | string | `"/data/proofs"` | Where generated proofs are written before being published |
| proving.scheduler.outputSizeLimit | string | `""` | Size limit for the proofs emptyDir |
| proving.scheduler.podAnnotations | object | `{}` | Annotations to add to the pods |
| proving.scheduler.pollIntervalSeconds | int | `30` | How often to look for a lifecycle to prove, in seconds |
| proving.scheduler.replicaCount | int | `1` | Replica count. Must stay 1 — it walks the backlog oldest-first from local markers. The template refuses to render any other value. |
| proving.scheduler.resources | object | `{}` | The Resources |
| proving.scheduler.sqlite.keepLastN | int | `0` | Keep all bodies: this scheduler works oldest-first, so a recent-window cache would prune exactly the lifecycles it still has to prove. |
| proving.worker.affinity | object | `{}` | Affinity, overriding the chart-wide one |
| proving.worker.autoscale | object | `{"enabled":false,"maxReplicas":"","minReplicas":0,"pollIntervalSeconds":15,"resources":{},"scaleDownAfterSeconds":180}` | Scale the workers from the depth of the proving queue.  Proving is by far the most expensive workload here, and it is idle whenever there is nothing to prove - but idle replicas still hold their CPU and memory requests and so keep nodes alive. A sidecar on proving-scheduler watches the queue and scales this Deployment between minReplicas and maxReplicas.  The chart stops rendering `replicas` when this is on, so that applying the release does not keep resetting the count the sidecar chose. |
| proving.worker.autoscale.enabled | bool | `false` | Whether to scale the workers from the queue depth. Requires the Role this chart creates, which grants scale access to this Deployment alone. |
| proving.worker.autoscale.maxReplicas | string | `""` | Ceiling on the proving cluster. Empty follows replicaCount. |
| proving.worker.autoscale.minReplicas | int | `0` | Replicas to hold while the queue is empty. 0 releases the nodes entirely, at the cost of recompiling the circuits (~100s) on scale-up. Set 1 to keep a warm worker instead. |
| proving.worker.autoscale.pollIntervalSeconds | int | `15` | How often to compare queue depth against the current count |
| proving.worker.autoscale.resources | object | `{}` | The Resources |
| proving.worker.autoscale.scaleDownAfterSeconds | int | `180` | How long the queue must stay empty before scaling down. Scaling up is immediate; scaling down waits, because the queue also empties briefly between the scheduler's prove-digest / prove-merge / prove-exhaust phases and dropping the workers there would recompile the circuits for no reason. Keep this comfortably above the longest gap between phases. |
| proving.worker.cacheSizeLimit | string | `""` | Size limit for the per-pod compiled circuit cache |
| proving.worker.deploymentAnnotations | object | `{}` | Annotations to add to the deployment |
| proving.worker.enabled | bool | `true` | Whether to deploy proving workers |
| proving.worker.extraEnvVars | list | `[]` | Additional environment variables |
| proving.worker.image.pullPolicy | string | `""` | Overrides the chart-wide pull policy |
| proving.worker.image.repository | string | `"minafoundation/dt-proving-worker"` | The image repository. NOTE: not published yet. |
| proving.worker.image.tag | string | `""` | Overrides the chart-wide tag |
| proving.worker.nodeSelector | object | `{}` | Node selector, overriding the chart-wide one. Proving is CPU and memory hungry and often wants its own node pool. |
| proving.worker.podAnnotations | object | `{}` | Annotations to add to the pods |
| proving.worker.proofsEnabled | bool | `true` | Defaults to true unlike the stack-wide config.proofsEnabled, since producing real proofs is the only reason to run this workload. |
| proving.worker.replicaCount | int | `3` | Number of workers. This is the size of the proving cluster: BullMQ hands each job to whichever replica is free. Ignored when `autoscale.enabled` is set, which manages the count instead. |
| proving.worker.resources | object | `{}` | The Resources |
| proving.worker.tolerations | list | `[]` | Tolerations, overriding the chart-wide ones |
| proxy | object | `{"clientMaxBodySize":"10m","deploymentAnnotations":{},"enabled":false,"image":{"pullPolicy":"","repository":"nginxinc/nginx-unprivileged","tag":"1.27-alpine"},"livenessProbe":{"failureThreshold":3,"httpGet":{"path":"/healthz","port":"http"},"initialDelaySeconds":10,"periodSeconds":20,"timeoutSeconds":5},"minaNodeUpstream":"","podAnnotations":{},"port":8080,"readTimeoutSeconds":120,"readinessProbe":{"failureThreshold":3,"httpGet":{"path":"/healthz","port":"http"},"initialDelaySeconds":5,"periodSeconds":10,"timeoutSeconds":5},"replicaCount":1,"resolver":"kube-dns.kube-system.svc.cluster.local","resources":{},"service":{"annotations":{},"port":80,"type":"ClusterIP"}}` | In-cluster reverse proxy, the compose stack's Caddy service translated to nginx. Required by ingress.mode `proxy` and ignored by the other modes: it is what strips /api, /indexer and /processor and fronts the Mina node at /mina, so a single hostname works on a controller that cannot rewrite. |
| proxy.clientMaxBodySize | string | `"10m"` | Largest request body accepted. Proposal content and vote payloads are the big ones; nginx's own default of 1m is on the tight side for proofs. |
| proxy.deploymentAnnotations | object | `{}` | Annotations to add to the deployment |
| proxy.enabled | bool | `false` | Whether to deploy the proxy |
| proxy.image.pullPolicy | string | `""` | Overrides the chart-wide pull policy |
| proxy.image.repository | string | `"nginxinc/nginx-unprivileged"` | The image repository. Unprivileged variant: it listens on a high port and runs as a non-root user, which the chart-wide securityContext needs. |
| proxy.image.tag | string | `"1.27-alpine"` | Tag. Pinned here rather than falling back to the chart-wide tag, which belongs to the application images. |
| proxy.livenessProbe | object | `{"failureThreshold":3,"httpGet":{"path":"/healthz","port":"http"},"initialDelaySeconds":10,"periodSeconds":20,"timeoutSeconds":5}` | Liveness probe. /healthz is served by nginx itself and proxies nowhere, so it reports on the proxy alone and not on what sits behind it. |
| proxy.minaNodeUpstream | string | `""` | Upstream for /mina, reproducing the Caddyfile's Mina node route. A plain URL, since the node is not part of this chart: an in-cluster Service or an external host, whichever fronts the daemon's GraphQL endpoint. Empty leaves the route out entirely, and the browser's NEXT_PUBLIC_MINA_NODE_URL 404s. |
| proxy.podAnnotations | object | `{}` | Annotations to add to the pods |
| proxy.port | int | `8080` | Port the container listens on. The unprivileged image defaults to 8080. |
| proxy.readTimeoutSeconds | int | `120` | How long to wait on an upstream response. Generous because some API reads rebuild witnesses from the lifecycle cache. |
| proxy.readinessProbe | object | `{"failureThreshold":3,"httpGet":{"path":"/healthz","port":"http"},"initialDelaySeconds":5,"periodSeconds":10,"timeoutSeconds":5}` | Readiness probe |
| proxy.replicaCount | int | `1` | Replica count. Stateless, and on the request path of every page load, so more than one is worth it wherever the web frontend has more than one. |
| proxy.resolver | string | `"kube-dns.kube-system.svc.cluster.local"` | DNS server used to resolve the /mina upstream at request time. Resolving lazily is what keeps an unreachable node from stopping nginx from starting, which would take the web app down with it. |
| proxy.resources | object | `{}` | The Resources |
| proxy.service.annotations | object | `{}` | Annotations to add to the service |
| proxy.service.port | int | `80` | The service port |
| proxy.service.type | string | `"ClusterIP"` | The service type |
| s3.proofsBucket | string | `"673156464838-mina-decentralized-treasury-proofs"` | Bucket holding generated proofs |
| s3.region | string | `"us-east-1"` | Region the buckets live in |
| s3.sqliteBucket | string | `"673156464838-mina-decentralized-treasury-sqlite"` | Bucket holding the lifecycle SQLite databases and their markers |
| s3.stakingLedgersBucket | string | `"673156464838-mina-staking-ledgers"` | Bucket holding staking ledger archives, in <epoch>-<hash>.tar.gz form |
| s3.syncImage | object | `{"pullPolicy":"IfNotPresent","repository":"amazon/aws-cli","resources":{},"securityContext":{"allowPrivilegeEscalation":false,"capabilities":{"drop":["ALL"]},"runAsNonRoot":true,"runAsUser":1000},"tag":"2.36.23"}` | Image used by the cache sync containers. Deliberately not the application image, which ships no AWS CLI. |
| s3.syncImage.resources | object | `{}` | The Resources |
| s3.syncImage.securityContext | object | `{"allowPrivilegeEscalation":false,"capabilities":{"drop":["ALL"]},"runAsNonRoot":true,"runAsUser":1000}` | Security context for the sync containers. Needs an explicit runAsUser because the aws-cli image defines no non-root user of its own. |
| secrets | list | `[]` | Secrets configuration |
| securityContext | object | `{"allowPrivilegeEscalation":false,"capabilities":{"drop":["ALL"]},"runAsNonRoot":true}` | The Security Context. Mirrors the compose stack's `no-new-privileges` and `cap_drop: ALL`; the image already runs as the unprivileged `node` user. |
| serviceAccount.annotations | object | `{}` | Annotations to add to the service account |
| serviceAccount.automount | bool | `true` | Automatically mount a ServiceAccount's API credentials? |
| serviceAccount.create | bool | `true` | Specifies whether a service account should be created |
| serviceAccount.name | string | `""` | The name of the service account to use. |
| sqlite.dataDirectory | string | `"/data/sqlite"` | Where the databases are mounted inside every pod that reads them |
| sqlite.existingClaim | string | `""` | Use an existing PersistentVolumeClaim instead of an emptyDir. Worth it only if re-downloading the cache on every pod start becomes slow. |
| sqlite.sizeLimit | string | `""` | Size limit for the emptyDir cache. Empty means no limit. |
| sqlite.syncIntervalSeconds | int | `60` | How often the sidecar re-syncs from S3. Lifecycles are ~15 days apart, so this can be generous. |
| tolerations | list | `[]` | Tolerations for pod assignment |
| votingLedgerScheduler | object | `{"deploymentAnnotations":{},"enabled":true,"extraEnvVars":[],"image":{"pullPolicy":"","repository":"minafoundation/dt-voting-ledger-scheduler","tag":""},"periodsPerLifecycle":4,"podAnnotations":{},"pollIntervalSeconds":30,"replicaCount":1,"resources":{},"sqlite":{"keepLastN":0},"stakingLedgersDirectory":"/staking-ledgers","stakingLedgersExistingClaim":"","stakingLedgersKeepLastN":2,"stakingLedgersSizeLimit":"","stakingLedgersSyncIntervalSeconds":300}` | Builds voting ledgers from staking ledger archives. The sole producer of the lifecycle SQLite databases, and the only workload that never touches Postgres. |
| votingLedgerScheduler.deploymentAnnotations | object | `{}` | Annotations to add to the deployment |
| votingLedgerScheduler.enabled | bool | `true` | Whether to deploy the voting ledger scheduler |
| votingLedgerScheduler.extraEnvVars | list | `[]` | Additional environment variables |
| votingLedgerScheduler.image.pullPolicy | string | `""` | Overrides the chart-wide pull policy |
| votingLedgerScheduler.image.repository | string | `"minafoundation/dt-voting-ledger-scheduler"` | The image repository. NOTE: not published yet as of 2026-08-14 — the built images so far are dt-api, dt-api-migrate, dt-indexer, dt-indexer-api, dt-processor and dt-processor-api. |
| votingLedgerScheduler.image.tag | string | `""` | Overrides the chart-wide tag |
| votingLedgerScheduler.periodsPerLifecycle | int | `4` | Staking ledger epochs spanned by one treasury lifecycle. Must match NUMBER_OF_PERIODS_PER_LIFECYCLE in the scheduler entrypoint: the sync uses it to work out which epochs begin a lifecycle and are therefore worth fetching at all. |
| votingLedgerScheduler.podAnnotations | object | `{}` | Annotations to add to the pods |
| votingLedgerScheduler.pollIntervalSeconds | int | `30` | How often to look for a new lifecycle to build, in seconds |
| votingLedgerScheduler.replicaCount | int | `1` | Replica count. Must stay 1 — it deletes and rebuilds lifecycle databases in place. The template refuses to render any other value. |
| votingLedgerScheduler.resources | object | `{}` | The Resources |
| votingLedgerScheduler.sqlite.keepLastN | int | `0` | Number of recent lifecycle bodies to keep; 0 keeps all. Markers are never pruned regardless, which is what stops the scheduler from reprocessing historical lifecycles after a restart. |
| votingLedgerScheduler.stakingLedgersDirectory | string | `"/staking-ledgers"` | Where staking ledger archives are mounted |
| votingLedgerScheduler.stakingLedgersExistingClaim | string | `""` | Use an existing claim for staking ledgers instead of an emptyDir |
| votingLedgerScheduler.stakingLedgersKeepLastN | int | `2` | How many *unproduced* lifecycles to hold staking ledgers for locally; 0 keeps every unproduced one. The sync only ever fetches archives that begin a lifecycle whose voting ledger is not in the SQLite bucket yet, and discards each one as soon as that voting ledger is published - so this is just the ceiling on work-in-hand, not a window over the whole bucket.  The poll loop only takes the newest, so 1 keeps it fed; a slightly larger value leaves room to reprocess a recent lifecycle by hand. |
| votingLedgerScheduler.stakingLedgersSizeLimit | string | `""` | Size limit for the staking ledger emptyDir |
| votingLedgerScheduler.stakingLedgersSyncIntervalSeconds | int | `300` | How often to re-check S3 for new staking ledger epochs, in seconds |
| web | object | `{"deploymentAnnotations":{},"enabled":true,"extraEnvVars":[],"image":{"pullPolicy":"","repository":"minafoundation/dt-web","tag":""},"livenessProbe":{"failureThreshold":3,"httpGet":{"path":"/","port":"http"},"initialDelaySeconds":20,"periodSeconds":20,"timeoutSeconds":5},"podAnnotations":{},"port":3100,"publicBaseUrl":"","publicEnv":{"NEXT_PUBLIC_EMPTY_NULLIFIER_ROOT":"","NEXT_PUBLIC_EMPTY_VOTING_LEDGER_ROOT":"","NEXT_PUBLIC_NETWORK_ID":"MAINNET","NEXT_PUBLIC_SLOT_DURATION_MS":"180000","NEXT_PUBLIC_STAKING_LEDGER_TO_VOTING_LEDGER_VERIFICATION_KEY_JSON":"","NEXT_PUBLIC_TREASURY_PROPOSAL_VERIFICATION_KEY_JSON":"","NEXT_PUBLIC_VOTE_REDUCER_VERIFICATION_KEY_JSON":""},"readinessProbe":{"failureThreshold":3,"httpGet":{"path":"/","port":"http"},"initialDelaySeconds":10,"periodSeconds":10,"timeoutSeconds":5},"replicaCount":1,"resources":{},"service":{"annotations":{},"port":3100,"type":"ClusterIP"}}` | Next.js frontend (apps/web). Built from the `web` stage of the Dockerfile, so it is a different image from every other service. |
| web.deploymentAnnotations | object | `{}` | Annotations to add to the deployment |
| web.enabled | bool | `true` | Whether to deploy the web frontend |
| web.extraEnvVars | list | `[]` | Additional environment variables |
| web.image.pullPolicy | string | `""` | Overrides the chart-wide pull policy |
| web.image.repository | string | `"minafoundation/dt-web"` | The image repository. NOTE: not published yet. |
| web.image.tag | string | `""` | Overrides the chart-wide tag |
| web.livenessProbe | object | `{"failureThreshold":3,"httpGet":{"path":"/","port":"http"},"initialDelaySeconds":20,"periodSeconds":20,"timeoutSeconds":5}` | Liveness probe |
| web.podAnnotations | object | `{}` | Annotations to add to the pods |
| web.port | int | `3100` | Port the container listens on |
| web.publicBaseUrl | string | `""` | Public origin the browser reaches this deployment on. Used to derive the same-origin API URLs, mirroring the Caddyfile's /api, /indexer and /processor prefixes. Usually the same host as ingress.host. |
| web.publicEnv | object | `{"NEXT_PUBLIC_EMPTY_NULLIFIER_ROOT":"","NEXT_PUBLIC_EMPTY_VOTING_LEDGER_ROOT":"","NEXT_PUBLIC_NETWORK_ID":"MAINNET","NEXT_PUBLIC_SLOT_DURATION_MS":"180000","NEXT_PUBLIC_STAKING_LEDGER_TO_VOTING_LEDGER_VERIFICATION_KEY_JSON":"","NEXT_PUBLIC_TREASURY_PROPOSAL_VERIFICATION_KEY_JSON":"","NEXT_PUBLIC_VOTE_REDUCER_VERIFICATION_KEY_JSON":""}` | Browser-facing configuration.  These are inlined into the client bundle at BUILD time, so the image must be built with the values for its target network. What is set here only reaches server-side rendering and cannot correct a mismatched build. Entries set here win over the values derived from publicBaseUrl. |
| web.readinessProbe | object | `{"failureThreshold":3,"httpGet":{"path":"/","port":"http"},"initialDelaySeconds":10,"periodSeconds":10,"timeoutSeconds":5}` | Readiness probe |
| web.replicaCount | int | `1` | Replica count |
| web.resources | object | `{}` | The Resources |
| web.service.annotations | object | `{}` | Annotations to add to the service |
| web.service.port | int | `3100` | The service port |
| web.service.type | string | `"ClusterIP"` | The service type |

