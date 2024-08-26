# pgt-gov-bot

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
| bot.config.discord.clientId | string | `""` | Discord Application ID |
| bot.config.discord.guildId | string | `""` | Discord Guild/Server ID |
| bot.config.discord.token | string | `""` | Discord API Token |
| bot.deploymentAnnotations | object | `{}` | Annotations to add to the deployment |
| bot.image.pullPolicy | string | `"IfNotPresent"` | The pullPolicy used when pulling the image |
| bot.image.repository | string | `"673156464838.dkr.ecr.us-west-2.amazonaws.com/pgt-gov-bot"` | The repository of the image |
| bot.image.tag | string | `"0.0.1"` |  |
| bot.imagePullSecrets | list | `[]` | The secrets used to pull the image |
| bot.livenessProbe | string | `nil` | Liveness check configuration |
| bot.podAnnotations | object | `{}` | Annotations to add to the pods |
| bot.podLabels | object | `{}` | Labels to add to the pods |
| bot.readinessProbe | string | `nil` | Readiness check configuration |
| bot.replicaCount | int | `1` | The number of replicas |
| bot.resources | object | `{}` | Resource limitations for the pods |
| fullnameOverride | string | `""` | The full release name override |
| ingress.annotations | object | `{}` | Annotations to add to the Ingress |
| ingress.className | string | `""` | Ingress class |
| ingress.enabled | bool | `false` | Enable Ingress |
| ingress.hosts[0].host | string | `"chart-example.local"` |  |
| ingress.hosts[0].paths[0].path | string | `"/"` |  |
| ingress.hosts[0].paths[0].pathType | string | `"ImplementationSpecific"` |  |
| ingress.tls | list | `[]` |  |
| nameOverride | string | `""` | The release name override |
| nodeSelector | object | `{}` | Node selector labels |
| ocvWeb.deploymentAnnotations | object | `{}` | Annotations to add to the deployment |
| ocvWeb.image.pullPolicy | string | `"IfNotPresent"` | The pullPolicy used when pulling the image |
| ocvWeb.image.repository | string | `"673156464838.dkr.ecr.us-west-2.amazonaws.com/pgt-gov-bot-ocv-web"` | The repository of the image |
| ocvWeb.image.tag | string | `"0.0.1"` |  |
| ocvWeb.imagePullSecrets | list | `[]` | The secrets used to pull the image |
| ocvWeb.livenessProbe | string | `nil` | Liveness check configuration |
| ocvWeb.podAnnotations | object | `{}` | Annotations to add to the pods |
| ocvWeb.podLabels | object | `{}` | Labels to add to the pods |
| ocvWeb.readinessProbe | string | `nil` | Readiness check configuration |
| ocvWeb.replicaCount | int | `1` | The number of replicas |
| ocvWeb.resources | object | `{}` | Resource limitations for the pods |
| ocvWeb.service.port | int | `80` | Service port |
| ocvWeb.service.type | string | `"ClusterIP"` | Service type |
| persistence.accessMode | string | `"ReadWriteOnce"` | The access mode of the PVC |
| persistence.annotations | object | `{}` | Annotations to add to the PVC |
| persistence.enabled | bool | `true` | Enable persistence using PVC |
| persistence.size | string | `"1Gi"` | The size of the PVC |
| persistence.storageClass | string | `"ebs-gp3-encrypted"` | The StorageClass of the PVC |
| podSecurityContext | object | `{}` |  |
| securityContext | object | `{}` |  |
| serviceAccount.annotations | object | `{}` |  |
| serviceAccount.automount | bool | `true` |  |
| serviceAccount.create | bool | `true` |  |
| serviceAccount.name | string | `""` |  |
| tolerations | list | `[]` | Tolerations |
| volumeMounts | list | `[]` |  |
| volumes | list | `[]` |  |

