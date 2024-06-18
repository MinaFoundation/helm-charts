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
| delegationProgramDB.host | string | `"localhost"` | Delegation Program Database Host |
| delegationProgramDB.name | string | `"postgres"` | Delegation Program Database Name |
| delegationProgramDB.password | string | `"postgres"` | Delegation Program Database Password |
| delegationProgramDB.port | string | `"5432"` | Delegation Program Database Port |
| delegationProgramDB.user | string | `"postgres"` | Delegation Program Database User |
| fullnameOverride | string | `""` | The full release name override |
| ingress.annotations | object | `{}` | The Ingress Annotations |
| ingress.className | string | `""` | The Ingress Class Name to use |
| ingress.enabled | bool | `false` | Whether to create an Ingress |
| ingress.hosts | list | `[{"host":"chart-example.local","paths":[{"path":"/","pathType":"ImplementationSpecific"}]}]` | The Ingress Hosts |
| ingress.tls | list | `[]` | The TLS configuration |
| leaderboardApi | object | `{"affinity":{},"cacheTimeout":300,"extraEnvVars":{},"image":{"pullPolicy":"IfNotPresent","repository":"673156464838.dkr.ecr.us-west-2.amazonaws.com/delegation-program-leaderboard-api","tag":"2.1.0"},"imagePullSecrets":[],"logFile":"./application.log","nodeSelector":{},"podAnnotations":{},"podSecurityContext":{},"replicaCount":1,"resources":{},"securityContext":{},"service":{"port":5000,"type":"ClusterIP"},"tolerations":[]}` | configuration options for leaderboard api deployment |
| leaderboardApi.affinity | object | `{}` | Affinity rules |
| leaderboardApi.cacheTimeout | int | `300` | Application cache timeout in seconds |
| leaderboardApi.extraEnvVars | object | `{}` | Extra Environment Variables |
| leaderboardApi.image.pullPolicy | string | `"IfNotPresent"` | The pullPolicy used when pulling the image |
| leaderboardApi.image.repository | string | `"673156464838.dkr.ecr.us-west-2.amazonaws.com/delegation-program-leaderboard-api"` | The repository of the image |
| leaderboardApi.image.tag | string | `"2.1.0"` | The tag of the image. Overrides the image tag whose default is the chart appVersion. |
| leaderboardApi.imagePullSecrets | list | `[]` | The secrets used to pull the image |
| leaderboardApi.logFile | string | `"./application.log"` | A path to an application log file |
| leaderboardApi.nodeSelector | object | `{}` | Node selector labels |
| leaderboardApi.podAnnotations | object | `{}` | Annotations to add to the pods |
| leaderboardApi.podSecurityContext | object | `{}` | The Pod Security Context |
| leaderboardApi.replicaCount | int | `1` | The number of replicas |
| leaderboardApi.resources | object | `{}` | Resource limitations for the pods |
| leaderboardApi.securityContext | object | `{}` | The Security Context |
| leaderboardApi.service.port | int | `5000` | The port of the service |
| leaderboardApi.service.type | string | `"ClusterIP"` | The type of service to create |
| leaderboardApi.tolerations | list | `[]` | Tolerations |
| leaderboardWeb | object | `{"affinity":{},"autoscaling":{"enabled":false,"maxReplicas":100,"minReplicas":1,"targetCPUUtilizationPercentage":80},"extraEnvVars":{},"image":{"pullPolicy":"IfNotPresent","repository":"673156464838.dkr.ecr.us-west-2.amazonaws.com/delegation-program-leaderboard","tag":"2.1.0"},"imagePullSecrets":[],"nodeSelector":{},"podAnnotations":{},"podSecurityContext":{},"replicaCount":1,"resources":{},"securityContext":{},"service":{"port":80,"type":"ClusterIP"},"tolerations":[]}` | configuration options for leaderboard web deployment |
| leaderboardWeb.affinity | object | `{}` | Affinity rules |
| leaderboardWeb.autoscaling.enabled | bool | `false` | Whether to enable autoscaling |
| leaderboardWeb.autoscaling.maxReplicas | int | `100` | The maximum number of pods |
| leaderboardWeb.autoscaling.minReplicas | int | `1` | The minimum number of pods |
| leaderboardWeb.autoscaling.targetCPUUtilizationPercentage | int | `80` | The metrics to use for autoscaling |
| leaderboardWeb.extraEnvVars | object | `{}` | Extra Environment Variables |
| leaderboardWeb.image.pullPolicy | string | `"IfNotPresent"` | The pullPolicy used when pulling the image |
| leaderboardWeb.image.repository | string | `"673156464838.dkr.ecr.us-west-2.amazonaws.com/delegation-program-leaderboard"` | The repository of the image |
| leaderboardWeb.image.tag | string | `"2.1.0"` | The tag of the image. Overrides the image tag whose default is the chart appVersion. |
| leaderboardWeb.imagePullSecrets | list | `[]` | The secrets used to pull the image |
| leaderboardWeb.nodeSelector | object | `{}` | Node selector labels |
| leaderboardWeb.podAnnotations | object | `{}` | Annotations to add to the pods |
| leaderboardWeb.podSecurityContext | object | `{}` | The Pod Security Context |
| leaderboardWeb.replicaCount | int | `1` | The number of replicas |
| leaderboardWeb.resources | object | `{}` | Resource limitations for the pods |
| leaderboardWeb.securityContext | object | `{}` | The Security Context |
| leaderboardWeb.service.port | int | `80` | The port of the service |
| leaderboardWeb.service.type | string | `"ClusterIP"` | The type of service to create |
| leaderboardWeb.tolerations | list | `[]` | Tolerations |
| nameOverride | string | `""` | The release name override |
| serviceAccount.annotations | object | `{}` | Annotations to add to the service account |
| serviceAccount.create | bool | `true` | Specifies whether a service account should be created |
| serviceAccount.name | string | `""` | If not set and create is true, a name is generated using the fullname template |

