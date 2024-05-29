# uptime-service-backend

![Version: 0.1.0](https://img.shields.io/badge/Version-0.1.0-informational?style=flat-square) ![Type: application](https://img.shields.io/badge/Type-application-informational?style=flat-square) ![AppVersion: 0.1.0](https://img.shields.io/badge/AppVersion-0.1.0-informational?style=flat-square)

A Helm chart for uptime-service-backend AKA Delegation Program Backend

**Homepage:** <https://docs.minaprotocol.com/node-operators/foundation-delegation-program>

## Source Code

* <https://github.com/MinaFoundation/uptime-service-backend/tree/main/src/delegation_backend>

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
| autoscaling.enabled | bool | `false` | Whether to enable HPA |
| autoscaling.maxReplicas | int | `10` | Maximum HPA replicas |
| autoscaling.minReplicas | int | `1` | Minimum HPA replicas |
| autoscaling.targetCPUUtilizationPercentage | int | `80` | Target threshold of CPU utilization |
| autoscaling.targetMemoryUtilizationPercentage | int | `80` | Target threshold of RAM utilization |
| backend.affinity | object | `{}` |  |
| backend.awsConfig.accountId | string | `nil` | AWS Account ID |
| backend.awsConfig.region | string | `nil` | AWS Region |
| backend.extraEnvVars | list | `[]` | Extra Environment Variables |
| backend.logLevel | string | `"info"` |  |
| backend.metrics.enabled | bool | `false` | Whether to enable prometheus metrics |
| backend.network | string | `nil` | Name of a testnet |
| backend.requestsPerPkHourly | int | `120` | Hourly rate limit per Mina node |
| backend.storage.keyspace.awsKeyspaceName | string | `nil` | Name of AWS Keyspace |
| backend.storage.local.path | string | `nil` | Path for storing submissions locally |
| backend.storage.s3.awsBucketNameSuffix | string | `nil` | Buckets are named `awsConfig.AccountId`-`awsBucketNameSuffix` |
| backend.verifySignatureDisabled | bool | `false` | Disable submission signature verification |
| backend.whitelistConfig.column | string | `nil` | Google spreadsheet column name |
| backend.whitelistConfig.enabled | bool | `false` | Whether to verify participants with Google sheet whitelist |
| backend.whitelistConfig.sheet | string | `nil` | Google spreadsheet sheet name |
| backend.whitelistConfig.spreadsheetId | string | `nil` | Google spreadsheet ID |
| fullnameOverride | string | `""` | The full release name override |
| image.pullPolicy | string | `"IfNotPresent"` | The pullPolicy used when pulling the image |
| image.repository | string | `"673156464838.dkr.ecr.us-west-2.amazonaws.com/uptime-service-backend"` | The repository of the image |
| image.tag | string | `"2.0.0rc5-cb6524c"` | The tag of the image. Overrides the image tag whose default is the chart appVersion. |
| imagePullSecrets | list | `[]` | The secrets used to pull the image |
| ingress.annotations | object | `{}` | Ingress Annotations |
| ingress.className | string | `"alb"` | Ingress class name |
| ingress.enabled | bool | `false` | Whether to enable ingress |
| ingress.hosts | list | `[]` |  |
| ingress.tls | list | `[]` |  |
| nameOverride | string | `""` | The release name override |
| nodeSelector | object | `{}` | Node selector labels |
| podAnnotations | object | `{}` | Annotations to add to the pods |
| podLabels | object | `{}` | The labels to add to the pods |
| podSecurityContext | object | `{}` | The Pod Security Context |
| replicaCount | int | `1` | The number of pods to be deployed for bot |
| resources | object | `{}` | Resource limitations for the pods |
| secret.gcpServiceAccount | string | `nil` | GCP service account json |
| secret.keyspaceCert.content | string | `nil` | Certificate content |
| secret.keyspaceCert.name | string | `nil` | Certificate file name(i.e. cert.crt) |
| secret.keyspaceCert.override | bool | `false` | Whether to override default certificate |
| securityContext | object | `{}` | The Security Context |
| service.port | int | `8080` | Kubernetes Service port |
| service.type | string | `"ClusterIP"` | Kubernetes Service type |
| serviceAccount.annotations | object | `{}` | Annotations to add to the service account |
| serviceAccount.automount | bool | `true` | Automatically mount a ServiceAccount's API credentials? |
| serviceAccount.create | bool | `true` | Specifies whether a service account should be created |
| serviceAccount.name | string | `""` | If not set and create is true, a name is generated using the fullname template |
| tolerations | list | `[]` | Tolerations |

