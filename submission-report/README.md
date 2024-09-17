# submission-report

![Version: 0.1.0](https://img.shields.io/badge/Version-0.1.0-informational?style=flat-square) ![Type: application](https://img.shields.io/badge/Type-application-informational?style=flat-square) ![AppVersion: 1.16.0](https://img.shields.io/badge/AppVersion-1.16.0-informational?style=flat-square)

A Helm chart for the submission report service

**Homepage:** <https://github.com/MinaFoundation/submission-report>

## Maintainers

| Name | Email | Url |
| ---- | ------ | --- |
| Mina Foundation DevOps team | <DevOps@MinaFoundation> |  |

## Source Code

* <https://github.com/MinaFoundation/submission-report>

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
| app.extraEnvVars | list | `[]` | List of extra environment variables |
| app.postgresDatabase | string | `""` | Postgres database name |
| app.postgresHost | string | `""` | Postgres host |
| app.postgresPassword | string | `""` | Postgres password |
| app.postgresPort | string | `""` | Postgres port |
| app.postgresUsername | string | `""` | Postgres username |
| fullnameOverride | string | `""` | The full release name override |
| image.pullPolicy | string | `"IfNotPresent"` | The pullPolicy used when pulling the image |
| image.repository | string | `"673156464838.dkr.ecr.us-west-2.amazonaws.com/submission-report"` | The repository of the image |
| image.tag | string | `"2.0.0rc1"` | The tag of the iamge. Overrides the image tag whose default is the chart appVersion. |
| imagePullSecrets | list | `[]` | The secrets used to pull the image |
| ingress.annotations | object | `{}` | Ingress annotations |
| ingress.className | string | `"alb"` | Ingress type |
| ingress.enabled | bool | `false` | Whether ingress should be enabled for the app |
| ingress.hosts | list | `[]` | A list of host configurations |
| ingress.tls | list | `[]` | A list of tls configurations |
| nameOverride | string | `""` | The release name override |
| nodeSelector | object | `{}` | Node selector labels |
| podAnnotations | object | `{}` | Annotations to add to the pods |
| podLabels | object | `{}` | Labels to add to the pods |
| podSecurityContext | object | `{}` | SecurityContext used for the pods |
| replicaCount | int | `1` | The number of pods to be deployed for bot |
| resources | object | `{}` | Resource limitations for the pods |
| securityContext | object | `{}` | SecurityContext |
| service.port | int | `5000` | Service port |
| service.type | string | `"ClusterIP"` | Service type |
| serviceAccount.annotations | object | `{}` | Annotations to add to the service account |
| serviceAccount.automount | bool | `true` | Automatically mount a ServiceAccount's API credentials? |
| serviceAccount.create | bool | `true` | Specifies whether a service account should be created |
| serviceAccount.name | string | `""` | The name of the service account to use. |
| tolerations | list | `[]` | Tolerations |

