# mina-archive

![Version: 3.0.0](https://img.shields.io/badge/Version-3.0.0-informational?style=flat-square) ![Type: application](https://img.shields.io/badge/Type-application-informational?style=flat-square) ![AppVersion: 2.0.0](https://img.shields.io/badge/AppVersion-2.0.0-informational?style=flat-square)

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
| dbBootstrap.createDatabase | bool | `true` | Instanciate the database on the database server |
| dbBootstrap.enabled | bool | `false` | Enable to dbBootstrap job to populate the database schema or dump |
| dbBootstrap.extraSqlFileUrls | list | `[]` | SQL file urls to pre-download before executing the SQL file urls |
| dbBootstrap.maxExpectedDurationInSeconds | int | `1800` | Set the bootstrap duration expected to be used by other pods when waiting for the bootstrap to complete, before reaching timeout |
| dbBootstrap.podAnnotations | object | `{}` | Annotations to apply to the pod  |
| dbBootstrap.postCustomSql | string | `"ALTER DATABASE {{ .Values.databaseName }} SET DEFAULT_TRANSACTION_ISOLATION TO SERIALIZABLE"` | Execute SQL inline command after loading the SQL file urls |
| dbBootstrap.sqlFileUrls | list | `[]` | SQL file urls to execute |
| dumpExporter.enabled | bool | `false` | Enabled dump exporter  |
| dumpExporter.podAnnotations | object | `{}` | Annotations to the  dump exporter  |
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
| missingBlocksGuardian.podAnnotations | object | `{}` | Annotations to the missing blocks guardian  |
| missingBlocksGuardian.precomputedBlocksUrl | string | `""` | URL to fetch the pre-computed blocks from |
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
| nodeSelector | object | `{}` | Node selector for all the pods |
| postgresClientDockerImage | string | `"bitnami/postgresql:16.2.0-debian-12-r18"` | Image to use as postgresql client, to export dumps for example |
| postgresql.auth.enablePostgresUser | bool | `false` | Enable the default postgres user |
| postgresql.auth.password | string | `"password"` | Password for the database |
| postgresql.auth.username | string | `"username"` | Username for the database |
| postgresql.enabled | bool | `true` | Enable local postgresql database server |
| postgresql.primary.extendedConfiguration | string | `"max_connections=500\nmax_locks_per_transaction=100\nmax_pred_locks_per_relation=100\nmax_pred_locks_per_transaction=5000\nmax_wal_size=2048\n"` | Extended configuration to configure postgresql server |
| postgresql.primary.persistence.enabled | bool | `true` | Enable the persistence for the postgresql server |
| postgresql.primary.persistence.size | string | `"8Gi"` | Size of the postgresql server volume |
| postgresql.primary.persistence.storageClass | string | `""` | Storage class for the postgresql server volume |
| postgresql.primary.resourcesPreset | string | `"nano"` | Resources preset to set resource requests and limits |
| serviceAccount.annotations | object | `{}` | Service account annotations |
| tolerations | list | `[]` | Toleration for all the pods |

