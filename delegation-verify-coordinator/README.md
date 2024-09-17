# delegation-verify-coordinator

![Version: 0.1.0](https://img.shields.io/badge/Version-0.1.0-informational?style=flat-square) ![Type: application](https://img.shields.io/badge/Type-application-informational?style=flat-square) ![AppVersion: 1.16.0](https://img.shields.io/badge/AppVersion-1.16.0-informational?style=flat-square)

A Helm chart for the delegation verify coordinator

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
| affinity | object | `{}` | affinity for the pod assignment |
| coordinator.aws.accessKeyID | string | `nil` | AWS Access Key ID |
| coordinator.aws.host | string | `"cassandra.us-west-2.amazonaws.com"` | AWS Cassandra Host |
| coordinator.aws.keyspace | string | `""` | Keyspace |
| coordinator.aws.port | string | `"9142"` | AWS Cassandra Port |
| coordinator.aws.region | string | `"us-west-2"` | AWS Region |
| coordinator.aws.s3Bucket | string | `"673156464838-uptime-service-backend"` | AWS S3 Bucket |
| coordinator.aws.secretAccessKey | string | `nil` | AWS Secret Access Key |
| coordinator.command.override | string | `nil` | override: the command to run |
| coordinator.envVars | list | `[]` | Environment Variables |
| coordinator.miniBatchNumber | int | `2` | The minimum batch number |
| coordinator.networkName | string | `""` | Network name |
| coordinator.noChecks | string | `""` | No Checks |
| coordinator.platform | string | `""` | Platform name |
| coordinator.postgres.db | string | `""` | Postgres database |
| coordinator.postgres.host | string | `"{{ .Release.Name }}-psql"` | Postgres Host |
| coordinator.postgres.password | string | `""` | Postgres password |
| coordinator.postgres.port | int | `5432` | Postgres Port |
| coordinator.postgres.roPassword | string | `""` | Postgres Read Only Password |
| coordinator.postgres.roUser | string | `""` | Postgres Read Only User |
| coordinator.postgres.user | string | `""` | Postgres user |
| coordinator.ssl.certfile | string | `nil` | SSL Cert File |
| coordinator.surveyIntervalMinutes | int | `20` | Survey Interval Minutes |
| coordinator.uptimeDaysForScore | string | `""` | The Uptime Days for Score |
| coordinator.worker.cpu.limit | string | `nil` | The CPU limit |
| coordinator.worker.cpu.request | string | `nil` | The CPU request |
| coordinator.worker.image | string | `""` | The image used for the worker |
| coordinator.worker.memory.limit | string | `nil` | The memory limit |
| coordinator.worker.memory.request | string | `nil` | The memory request |
| coordinator.worker.tag | string | `""` | The image tag used for the worker |
| coordinator.worker.ttlSecondsAfterFinished | int | `43200` | TTL Seconds After Finished |
| fullnameOverride | string | `nil` | Full name override |
| image.pullPolicy | string | `"IfNotPresent"` | The image pull policy |
| image.repository | string | `""` | The image repository |
| image.tag | string | `""` | The image tag |
| nameOverride | string | `nil` | Name override |
| podAnnotations | object | `{}` | Annotations to add to the pods |
| podLabels | object | `{}` | Label to add to the pods |
| replicas | int | `1` | Replica count |
| resources | object | `{}` | The Resources |
| secret.gcpServiceAccount | string | `nil` | The gcp Service Account |
| service.port | int | `80` | The port of the service |
| service.type | string | `"ClusterIP"` | The type of service to create |
| serviceAccount.automount | bool | `true` | Automatically mount a ServiceAccount's API credentials? |
| serviceAccount.coordinator.annotations | object | `{}` | Annotations to add to the service account |
| serviceAccount.create | bool | `true` | Specifies whether a service account should be created |
| serviceAccount.name | string | `""` | The name of the service account to use. |
| serviceAccount.worker.annotations | object | `{}` | Annotations to add to the service account |

