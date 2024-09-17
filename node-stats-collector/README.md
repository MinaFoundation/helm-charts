# node-stats-collector

![Version: 0.2.0](https://img.shields.io/badge/Version-0.2.0-informational?style=flat-square) ![Type: application](https://img.shields.io/badge/Type-application-informational?style=flat-square) ![AppVersion: 0.3.0](https://img.shields.io/badge/AppVersion-0.3.0-informational?style=flat-square)

A Helm chart for Kubernetes

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
| autoscaling.enabled | bool | `false` | Enable autoscaling |
| autoscaling.maxReplicas | int | `100` | The maximum number of replicas |
| autoscaling.minReplicas | int | `1` | The minimum number of replicas |
| autoscaling.targetCPUUtilizationPercentage | int | `80` | The target CPU utilization percentage |
| extraEnvVars | object | `{}` | Extra environment variables |
| fullnameOverride | string | `""` | The full name override |
| image.pullPolicy | string | `"IfNotPresent"` | The pullPolicy used when pulling the image |
| image.repository | string | `"673156464838.dkr.ecr.us-west-2.amazonaws.com/node-stats-collector"` | The repository of the image |
| image.tag | string | `"2023.09"` | Overrides the image tag whose default is the chart appVersion. |
| ingress.annotations | object | `{}` | The Ingress Annotations |
| ingress.className | string | `""` | The Ingress Class Name to use |
| ingress.enabled | bool | `false` | Whether to create an Ingress |
| ingress.hosts | list | `[{"host":"chart-example.local","paths":[{"path":"/","pathType":"ImplementationSpecific"}]}]` | The Ingress Hosts |
| ingress.tls | list | `[]` |  |
| nameOverride | string | `""` | The name override |
| nodeSelector | object | `{}` | Node selector |
| nodestats.endpoint | string | `""` | Endpoint to collect node stats |
| nodestats.index | string | `"node-stats-errors"` | Index to store node stats |
| nodestats.metrics.enabled | bool | `true` | Enable Metrics collection |
| podAnnotations | object | `{}` | Annotations to add to the pods |
| podSecurityContext | object | `{}` | The Pod Security Context |
| replicaCount | int | `1` | The number of replicas |
| resources | object | `{}` | Resource limitations for the pods |
| securityContext | object | `{}` | The Security Context |
| service.port | int | `8080` | The service port |
| service.type | string | `"ClusterIP"` | The service type |
| serviceAccount.annotations | object | `{}` | Annotations to add to the service account |
| serviceAccount.create | bool | `true` | Specifies whether a service account should be created |
| serviceAccount.name | string | `""` | The name of the service account to use. |
| tolerations | list | `[]` | Tolerations |

