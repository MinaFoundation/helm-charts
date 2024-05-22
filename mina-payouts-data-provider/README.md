# mina-payouts-data-provider

![Version: 0.1.0](https://img.shields.io/badge/Version-0.1.0-informational?style=flat-square) ![Type: application](https://img.shields.io/badge/Type-application-informational?style=flat-square) ![AppVersion: 1.16.0](https://img.shields.io/badge/AppVersion-1.16.0-informational?style=flat-square)

A Helm chart for Kubernetes

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
| affinity | object | `{}` | Affinity rules |
| autoscaling.enabled | bool | `false` | Whether to enable autoscaling |
| autoscaling.maxReplicas | int | `3` | The maximum number of pods |
| autoscaling.minReplicas | int | `1` | The minimum number of pods |
| autoscaling.targetCPUUtilizationPercentage | int | `80` | The metrics to use for autoscaling |
| fullnameOverride | string | `""` | The full release name override |
| image.pullPolicy | string | `"IfNotPresent"` | The pullPolicy used when pulling the image |
| image.repository | string | `"673156464838.dkr.ecr.us-west-2.amazonaws.com/mina-payouts-data-provider"` | The repository of the image |
| image.tag | string | `"2.5.1-da23d50"` | The tag of the image. Overrides the image tag whose default is the chart appVersion. |
| imagePullSecrets | list | `[]` | The secrets used to pull the image |
| ingress.annotations | object | `{}` | The Ingress Annotations |
| ingress.className | string | `""` | The Ingress Class Name to use |
| ingress.enabled | bool | `false` | Whether to create an Ingress |
| ingress.hosts | list | `[]` | The Ingress Hosts |
| ingress.tls | list | `[]` | The TLS configuration |
| livenessProbe | object | `{"httpGet":{"path":"/health","port":"http"}}` | The Liveness Probe |
| minaPayoutsDataProvider.archiveDBRecencyThreshold | int | `10` | The Archive DB Recency Threshold |
| minaPayoutsDataProvider.blockDBQuery.host | string | `"http://localhost"` | The Host of the Archive DB |
| minaPayoutsDataProvider.blockDBQuery.name | string | `"database"` | The Name of the Archive DB |
| minaPayoutsDataProvider.blockDBQuery.password | string | `"password"` | The Password for the Archive DB |
| minaPayoutsDataProvider.blockDBQuery.port | int | `5432` | The Port of the Archive DB |
| minaPayoutsDataProvider.blockDBQuery.ssl.enabled | bool | `false` | Whether SSL is enabled |
| minaPayoutsDataProvider.blockDBQuery.ssl.rootCertificateBase64 | string | `nil` | The Root Certificate Base64 |
| minaPayoutsDataProvider.blockDBQuery.user | string | `"user"` | The User for the Archive DB |
| minaPayoutsDataProvider.blockDBQuery.version | string | `"v1"` | The Version used to query the Archive DB (accepted values are: v1 (mainnet), v2 (berkeley)) |
| minaPayoutsDataProvider.checkNodes | list | `[]` | List of GraphQL Endpoints to query |
| minaPayoutsDataProvider.envVars | list | `[]` | Environment Variables |
| minaPayoutsDataProvider.ledgerDBCommand.host | string | `"http://localhost"` | The Host of the Ledger DB (Read-Write) |
| minaPayoutsDataProvider.ledgerDBCommand.name | string | `"database"` | The Name of the Ledger DB (Read-Write) |
| minaPayoutsDataProvider.ledgerDBCommand.password | string | `"password"` | The Password for the Ledger DB (Read-Write) |
| minaPayoutsDataProvider.ledgerDBCommand.port | int | `5432` | The Port of the Ledger DB (Read-Write) |
| minaPayoutsDataProvider.ledgerDBCommand.ssl.enabled | bool | `false` | Whether SSL is enabled |
| minaPayoutsDataProvider.ledgerDBCommand.ssl.rootCertificateBase64 | string | `nil` | The Root Certificate Base64 |
| minaPayoutsDataProvider.ledgerDBCommand.user | string | `"user"` | The User for the Ledger DB (Read-Write) |
| minaPayoutsDataProvider.ledgerDBQuery.bootstrap.delay | int | `30` | The Delay in seconds before bootstrapping the Ledger DB in seconds |
| minaPayoutsDataProvider.ledgerDBQuery.bootstrap.enabled | bool | `false` | Whether to bootstrap the Ledger DB |
| minaPayoutsDataProvider.ledgerDBQuery.bootstrap.image.repository | string | `"postgres"` | The Repository of the bootstrap image |
| minaPayoutsDataProvider.ledgerDBQuery.bootstrap.image.tag | string | `"latest"` | The Tag of the bootstrap image |
| minaPayoutsDataProvider.ledgerDBQuery.bootstrap.schemaURL | string | `"https://raw.githubusercontent.com/jrwashburn/mina-payouts-data-provider/main/deploy/db-setup/stakesDb.sql"` | The Schema URL to bootstrap the Ledger DB |
| minaPayoutsDataProvider.ledgerDBQuery.host | string | `"http://localhost"` | The Host of the Ledger DB (Read-Only) |
| minaPayoutsDataProvider.ledgerDBQuery.name | string | `"database"` | The Name of the Ledger DB (Read-Only) |
| minaPayoutsDataProvider.ledgerDBQuery.password | string | `"password"` | The Password for the Ledger DB (Read-Only) |
| minaPayoutsDataProvider.ledgerDBQuery.port | int | `5432` | The Port of the Ledger DB (Read-Only) |
| minaPayoutsDataProvider.ledgerDBQuery.ssl.enabled | bool | `false` | Whether SSL is enabled |
| minaPayoutsDataProvider.ledgerDBQuery.ssl.rootCertificateBase64 | string | `nil` | The Root Certificate Base64 |
| minaPayoutsDataProvider.ledgerDBQuery.user | string | `"user"` | The User for the Ledger DB (Read-Only) |
| minaPayoutsDataProvider.ledgerUploadAPI.password | string | `"ledger-upload-api-password"` | The Password for the Ledger Upload API |
| minaPayoutsDataProvider.ledgerUploadAPI.user | string | `"ledger-upload-api-user"` | The User for the Ledger Upload API |
| minaPayoutsDataProvider.numSlotsInEpoch | int | `7140` | The number of slots in an epoch |
| nameOverride | string | `""` | The release name override |
| nodeSelector | object | `{}` | Node selector labels |
| podAnnotations | object | `{}` | Annotations to add to the pods |
| podSecurityContext | object | `{}` | The Pod Security Context |
| postgresql.create | bool | `false` | Whether to use the PostgreSQL chart |
| readinessProbe | object | `{"httpGet":{"path":"/health","port":"http"}}` | The Readiness Probe |
| replicaCount | int | `1` | The number of replicas |
| resources | object | `{}` | Resource limitations for the pods |
| securityContext | object | `{}` | The Security Context |
| service.port | int | `8080` | The port of the service |
| service.type | string | `"ClusterIP"` | The type of service to create |
| serviceAccount.annotations | object | `{}` | Annotations to add to the service account |
| serviceAccount.create | bool | `true` | Specifies whether a service account should be created |
| serviceAccount.name | string | `""` | If not set and create is true, a name is generated using the fullname template |
| tolerations | list | `[]` | Tolerations |

