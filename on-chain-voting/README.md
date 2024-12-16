# on-chain-voting

![Version: 0.2.0](https://img.shields.io/badge/Version-0.2.0-informational?style=flat-square) ![Type: application](https://img.shields.io/badge/Type-application-informational?style=flat-square) ![AppVersion: 1.16.0](https://img.shields.io/badge/AppVersion-1.16.0-informational?style=flat-square)

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
| fullnameOverride | string | `""` | Full name override |
| nameOverride | string | `""` | Name override |
| postgresql.auth.database | string | `"on-chain-voting"` | Default database name |
| postgresql.auth.enablePostgresUser | bool | `false` | Enable the default postgres user |
| postgresql.auth.password | string | `"ZhSYoKNUoyZPBftuNYiA6WqkG7Gpak"` | Default Password for the database |
| postgresql.auth.username | string | `"mina"` | Default Username for the database |
| postgresql.create | bool | `true` | Whether to deploy a PostgreSQL server to satisfy the application database requirements |
| postgresql.global.storageClass | string | `"ebs-gp3-encrypted"` | The Storage Class to use |
| postgresql.primary.initdb.password | string | `"ZhSYoKNUoyZPBftuNYiA6WqkG7Gpak"` | The default password to use to initialize the database |
| postgresql.primary.initdb.user | string | `"mina"` | The default user to use to initialize the database |
| postgresql.primary.name | string | `"on-chain-voting"` | Name of the PostgreSQL database |
| postgresql.primary.persistence.enabled | bool | `false` | Enable persistence using PVC |
| postgresql.primary.persistence.size | string | `"1Gi"` | The size of the PVC |
| server.affinity | object | `{}` | Affinity |
| server.allowedOrigins | string | `"*"` | Allow Origins |
| server.archivePostgresConnectionString | string | `"postgres://mina@postgres:5432/archive"` | Archive Postgres Connection String |
| server.args | list | `[]` | The arguments to pass at runtime |
| server.deploymentAnnotations | object | `{}` | Annotations to add to deployments |
| server.extraEnvVars | object | `{}` | Extra Environment variables |
| server.image.imagePullSecrets | list | `[]` | The secrets used to pull the image |
| server.image.pullPolicy | string | `"IfNotPresent"` | The image pull policy |
| server.image.repository | string | `"673156464838.dkr.ecr.us-west-2.amazonaws.com/on-chain-voting-server"` | The image repository |
| server.image.tag | string | `"0.1.0"` | Overrides the image tag whose default is the chart appVersion. |
| server.ledgersBucket | string | `"673156464838-mina-staking-ledgers"` | Stacking ledgers S3 bucket |
| server.lifecycle | object | `{"preStop":{"exec":{"command":["sh","-c","sleep 15 && kill -SIGQUIT 1"]}}}` | Lifecycle hooks |
| server.network | string | `"mainnet"` | Mina Network |
| server.nodeSelector | object | `{}` | Node Selector |
| server.podAnnotations | object | `{}` | Annotations to add to the pods |
| server.podSecurityContext | object | `{}` | The Pod Security Context |
| server.postgresConnectionString | string | `""` | Postgres Connection String |
| server.replicaCount | int | `1` | The number of replicas |
| server.resources | object | `{}` | Resources |
| server.securityContext | object | `{}` | The Security Context |
| server.service.port | int | `8080` | The service port |
| server.service.type | string | `"ClusterIP"` | The service type |
| server.tolerations | list | `[]` | Tolerations |
| serviceAccount.annotations | object | `{}` | Annotations to add to the service account |
| serviceAccount.create | bool | `true` | Specifies whether a service account should be created |
| serviceAccount.name | string | `""` | The name of the service account to use. |
| web.affinity | object | `{}` | Affinity |
| web.apiBaseURL | string | `""` | API base URL |
| web.args | list | `[]` | The arguments to pass at runtime |
| web.deploymentAnnotations | object | `{}` | Annotations to add to deployments |
| web.extraEnvVars | object | `{}` | Extra Environment variables |
| web.image.imagePullSecrets | list | `[]` | The secrets used to pull the image |
| web.image.pullPolicy | string | `"IfNotPresent"` | The image pull policy |
| web.image.repository | string | `"673156464838.dkr.ecr.us-west-2.amazonaws.com/on-chain-voting-web"` | The image repository |
| web.image.tag | string | `"0.1.0"` | Overrides the image tag whose default is the chart appVersion. |
| web.ingress.annotations | object | `{}` | The Ingress Annotations |
| web.ingress.className | string | `""` | The Ingress Class Name to use |
| web.ingress.enabled | bool | `false` | Whether to create an Ingress |
| web.ingress.hosts | list | `[]` | The Ingress Hosts |
| web.ingress.tls | list | `[]` | The TLS configuration |
| web.lifecycle | object | `{"preStop":{"exec":{"command":["sh","-c","sleep 15 && kill -SIGQUIT 1"]}}}` | Lifecycle hooks |
| web.nextPublicApiBaseURL | string | `""` | Next Public API base URL |
| web.nextPublicReleaseStage | string | `"production"` | Next Public Release Stage |
| web.nodeSelector | object | `{}` | Node Selector |
| web.podAnnotations | object | `{}` | Annotations to add to the pods |
| web.podSecurityContext | object | `{}` | The Pod Security Context |
| web.releaseStage | string | `"production"` | Release stage |
| web.replicaCount | int | `1` | The number of replicas |
| web.resources | object | `{}` | Resources |
| web.securityContext | object | `{}` | The Security Context |
| web.service.port | int | `3000` | The service port |
| web.service.type | string | `"ClusterIP"` | The service type |
| web.tolerations | list | `[]` | Tolerations |

