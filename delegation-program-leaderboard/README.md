# delegation-program-leaderboard

![Version: 0.1.0](https://img.shields.io/badge/Version-0.1.0-informational?style=flat-square) ![Type: application](https://img.shields.io/badge/Type-application-informational?style=flat-square) ![AppVersion: 1.16.0](https://img.shields.io/badge/AppVersion-1.16.0-informational?style=flat-square)

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
| autoscaling.enabled | bool | `false` | Whether to enable autoscaling |
| autoscaling.maxReplicas | int | `100` | The maximum number of pods |
| autoscaling.minReplicas | int | `1` | The minimum number of pods |
| autoscaling.targetCPUUtilizationPercentage | int | `80` | The metrics to use for autoscaling |
| fullnameOverride | string | `""` | The full release name override |
| image.pullPolicy | string | `"IfNotPresent"` | The pullPolicy used when pulling the image |
| image.repository | string | `"673156464838.dkr.ecr.us-west-2.amazonaws.com/delegation-program-leaderboard"` | The repository of the image |
| image.tag | string | `"2.0.2"` | The tag of the image. Overrides the image tag whose default is the chart appVersion. |
| imagePullSecrets | list | `[]` | The secrets used to pull the image |
| ingress.annotations | object | `{}` | The Ingress Annotations |
| ingress.className | string | `""` | The Ingress Class Name to use |
| ingress.enabled | bool | `false` | Whether to create an Ingress |
| ingress.hosts | list | `[{"host":"chart-example.local","paths":[{"path":"/","pathType":"ImplementationSpecific"}]}]` | The Ingress Hosts |
| ingress.tls | list | `[]` | The TLS configuration |
| leaderboard.dbHost | string | `"localhost"` | Leaderboard Database Host |
| leaderboard.dbName | string | `"postgres"` | Leaderboard Database Name |
| leaderboard.dbPassword | string | `"postgres"` | Leaderboard Database Password |
| leaderboard.dbPort | string | `"5432"` | Leaderboard Database Port |
| leaderboard.dbUser | string | `"postgres"` | Leaderboard Database User |
| leaderboard.envVars | object | `{}` | Extra Environment Variables |
| nameOverride | string | `""` | The release name override |
| nodeSelector | object | `{}` | Node selector labels |
| podAnnotations | object | `{}` | Annotations to add to the pods |
| podSecurityContext | object | `{}` | The Pod Security Context |
| replicaCount | int | `1` | The number of replicas |
| resources | object | `{}` | Resource limitations for the pods |
| securityContext | object | `{}` | The Security Context |
| service.port | int | `80` | The port of the service |
| service.type | string | `"ClusterIP"` | The type of service to create |
| serviceAccount.annotations | object | `{}` | Annotations to add to the service account |
| serviceAccount.create | bool | `true` | Specifies whether a service account should be created |
| serviceAccount.name | string | `""` | If not set and create is true, a name is generated using the fullname template |
| tolerations | list | `[]` | Tolerations |

