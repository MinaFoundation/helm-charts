# mina-archive

![Version: 4.0.0](https://img.shields.io/badge/Version-4.0.0-informational?style=flat-square) ![Type: application](https://img.shields.io/badge/Type-application-informational?style=flat-square) ![AppVersion: 2.1.0](https://img.shields.io/badge/AppVersion-2.1.0-informational?style=flat-square)

A Helm chart for Mina Protocol's berkeley archive node

**Homepage:** <https://minaprotocol.com/>

## Requirements

| Repository | Name | Version |
|------------|------|---------|
| https://charts.bitnami.com/bitnami | postgresql | * |

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
| affinity | object | `{}` |  |
| databaseName | string | `"archive"` | Database name of the archive node |
| dbBootstrap.annotations | object | `{}` | Annotations to apply to the job |
| dbBootstrap.createDatabase | bool | `false` | Instanciate the database on the database server. The published dump opens with its own `CREATE DATABASE`, so leave this disabled when restoring one. Enable it when loading a bare schema instead. |
| dbBootstrap.enabled | bool | `false` | Enable to dbBootstrap job to populate the database schema or dump |
| dbBootstrap.extraSqlFileUrls | list | `[]` | SQL file urls to pre-download before executing the SQL file urls. Templated in the same way as sqlFileUrls. |
| dbBootstrap.maxExpectedDurationInSeconds | int | `7200` | Set the bootstrap duration expected to be used by other pods when waiting for the bootstrap to complete, before reaching timeout. Restoring a published dump is a long job, the devnet one is around 400MB compressed, so this allows well beyond the download and restore time. |
| dbBootstrap.podAnnotations | object | `{}` | Annotations to apply to the pod |
| dbBootstrap.postCustomSql | string | `"ALTER DATABASE {{ .Values.databaseName }} SET DEFAULT_TRANSACTION_ISOLATION TO SERIALIZABLE"` | Execute SQL inline command after loading the SQL file urls |
| dbBootstrap.sqlFileUrls | list | `["https://storage.googleapis.com/mina-archive-dumps/{{ .Values.network }}-archive-dump-[DATE]_0000.sql.tar.gz"]` | SQL file urls to execute. Templated, so `.Values` are available, and `[DATE]` is replaced at runtime with the current date (YYYY-MM-DD). Defaults to the daily dump o1-labs publishes for the network. |
| dumpExporter.enabled | bool | `false` | Enabled dump exporter. Opt in, it publishes a dump of your own database to an S3 bucket you control and needs credentials for it. |
| dumpExporter.podAnnotations | object | `{}` | Annotations to the  dump exporter |
| dumpExporter.s3.bucket | string | `""` | S3 bucket to export the dump to |
| dumpExporter.schedule | string | `"@midnight"` | Frequency to execute the  dump exporter |
| dumpExporter.suspend | bool | `false` | Suspend the  dump exporter execution |
| dumpExporter.ttlSecondsAfterFinished | int | `86400` | Seconds before cleaning up the  dump exporter execution |
| externalDatabase.enabled | bool | `false` |  |
| externalDatabase.host | string | `"host"` | Host for external database connection |
| externalDatabase.password | string | `"password"` | Password of external database connection |
| externalDatabase.port | int | `5432` | Port of external database connection |
| externalDatabase.username | string | `"username"` | Username of external database connection |
| image.pullPolicy | string | `"IfNotPresent"` | Image pull policy |
| image.repository | string | `"gcr.io/o1labs-192920/mina-archive"` | Docker image repository |
| image.tag | string | `"2.0.0berkeley-rc1-1551e2f-focal"` | Docker image tag |
| missingBlocksGuardian.autoImportBlockUrl | string | `""` | URL to auto import a block when running the missing blocks guardian |
| missingBlocksGuardian.enabled | bool | `true` | Enabled missing blocks guardian |
| missingBlocksGuardian.podAnnotations | object | `{}` | Annotations to the missing blocks guardian |
| missingBlocksGuardian.precomputedBlocksUrl | string | `"https://storage.googleapis.com/mina_network_block_data"` | URL to fetch the pre-computed blocks from. The guardian appends /<network>-<height>-<state_hash>.json, which matches the layout of the bucket o1-labs publishes. |
| missingBlocksGuardian.schedule | string | `"@hourly"` | Frequency to execute the missing blocks guardian |
| missingBlocksGuardian.suspend | bool | `false` | Suspend the missing blocks guardian execution |
| missingBlocksGuardian.ttlSecondsAfterFinished | int | `86400` | Seconds before cleaning up the missing blocks guardian execution |
| network | string | `"network"` | Mina network name (e.g.: `mainnet`, `devnet`) |
| node.configFileUrl | string | `""` | Config file url to be downloaded and used as config file before the server starts |
| node.extraArgs | list | `[]` | Extra arguments for the mina archive process |
| node.extraEnvVars | list | `[]` | Extra environment variables for the mina archive process |
| node.metrics.enabled | bool | `true` | Enable metric service |
| node.podAnnotations | object | `{}` | Annotations to the mina archive pods |
| node.ports.metrics | int | `10002` | Mina archive metric port number |
| node.ports.rpc | int | `3086` | Mina archive RPC port number |
| node.readinessProbe | object | `{"exec":{"command":["bash","/scripts/archive-readiness.sh"]}}` | Readiness probe configuration |
| node.replicas | int | `1` | Replicas number for the archive node deployment |
| node.resources | object | `{}` | Resources for the mina archive pods |
| node.service.annotations | object | `{}` | Annotations to the mina archive service |
| node.service.labels | object | `{}` | Labels to the mina archive service |
| nodeApi.enableGraphiql | bool | `false` | Serve the GraphiQL playground at `/` |
| nodeApi.enableIntrospection | bool | `false` | Allow GraphQL schema introspection |
| nodeApi.enableLogging | bool | `false` | Enable request logging |
| nodeApi.enabled | bool | `false` | Enable the archive node GraphQL API (o1-labs/Archive-Node-API) |
| nodeApi.extraEnvVars | list | `[]` | Extra environment variables for the archive node API process |
| nodeApi.image.pullPolicy | string | `"IfNotPresent"` | Image pull policy |
| nodeApi.image.repository | string | `"ghcr.io/o1-labs/archive-node-api"` | Docker image repository |
| nodeApi.image.tag | string | `"0.0.9"` | Docker image tag |
| nodeApi.ingress.annotations | object | `{}` | The Ingress Annotations |
| nodeApi.ingress.className | string | `""` | The Ingress Class Name to use |
| nodeApi.ingress.enabled | bool | `false` | Whether to create an Ingress for the archive node API |
| nodeApi.ingress.hosts | list | `[]` | The Ingress Hosts |
| nodeApi.ingress.tls | list | `[]` | The TLS configuration |
| nodeApi.jaeger.enabled | bool | `false` | Emit traces to a Jaeger collector |
| nodeApi.jaeger.endpoint | string | `""` | Jaeger collector endpoint (e.g.: `http://jaeger:14268/api/traces`) |
| nodeApi.jaeger.serviceName | string | `"archive-api"` | Service name reported to Jaeger |
| nodeApi.livenessProbe | object | `{"httpGet":{"path":"/healthcheck","port":"http"},"initialDelaySeconds":15,"periodSeconds":20}` | Liveness probe configuration |
| nodeApi.podAnnotations | object | `{}` | Annotations to the archive node API pods |
| nodeApi.ports.http | int | `8080` | Port the GraphQL server listens on |
| nodeApi.readinessProbe | object | `{"httpGet":{"path":"/healthcheck","port":"http"},"initialDelaySeconds":5,"periodSeconds":10}` | Readiness probe configuration |
| nodeApi.replicas | int | `1` | Replicas number for the archive node API deployment |
| nodeApi.resources | object | `{}` | Resources for the archive node API pods |
| nodeApi.service.annotations | object | `{}` | Annotations to the archive node API service |
| nodeApi.service.labels | object | `{}` | Labels to the archive node API service |
| nodeApi.service.port | int | `8080` | Port of the archive node API service |
| nodeApi.service.type | string | `"ClusterIP"` | Type of the archive node API service |
| nodeSelector | object | `{}` | Node selector for all the pods |
| postgresClientDockerImage | string | `"postgres:17-alpine"` | Image to use as postgresql client, used by the dump exporter. Only needs psql/pg_dump, so it is not tied to the Bitnami image layout. Keep the major version at or above the server, pg_dump refuses a newer one. |
| postgresql.auth.enablePostgresUser | bool | `false` | Enable the default postgres user |
| postgresql.auth.password | string | `"password"` | Password for the database |
| postgresql.auth.username | string | `"username"` | Username for the database |
| postgresql.enabled | bool | `true` | Enable local postgresql database server |
| postgresql.image.repository | string | `"bitnamilegacy/postgresql"` |  |
| postgresql.image.tag | string | `"17.6.0-debian-12-r4"` |  |
| postgresql.primary.extendedConfiguration | string | `"max_connections=500\nmax_locks_per_transaction=100\nmax_pred_locks_per_relation=100\nmax_pred_locks_per_transaction=5000\nmax_wal_size=2048\n"` | Extended configuration to configure postgresql server |
| postgresql.primary.persistence.enabled | bool | `true` | Enable the persistence for the postgresql server |
| postgresql.primary.persistence.size | string | `"8Gi"` | Size of the postgresql server volume |
| postgresql.primary.persistence.storageClass | string | `""` | Storage class for the postgresql server volume |
| postgresql.primary.resourcesPreset | string | `"nano"` | Resources preset to set resource requests and limits |
| serviceAccount.annotations | object | `{}` | Service account annotations |
| tolerations | list | `[]` | Toleration for all the pods |

