# pgt-leader-bot

![Version: 0.1.0](https://img.shields.io/badge/Version-0.1.0-informational?style=flat-square) ![Type: application](https://img.shields.io/badge/Type-application-informational?style=flat-square) ![AppVersion: 1.16.0](https://img.shields.io/badge/AppVersion-1.16.0-informational?style=flat-square)

A Helm chart for Kubernetes

## Requirements

| Repository | Name | Version |
|------------|------|---------|
| https://charts.bitnami.com/bitnami | mongodb | 15.6.19 |

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
| api.logLevel | string | `"INFO"` | Logs Level |
| bot.logLevel | string | `"INFO"` | Logs Level |
| config.discord.forumChannelId | string | `"chanid"` | Discord Channel ID |
| config.discord.guildId | string | `"myguildid"` | Discord Guild/Server ID |
| config.discord.token | string | `"mytoken"` | Discord API Token |
| config.github.token | string | `"mytoken"` | Github API Token |
| config.googleSheets.credentials | string | `"JSON data"` | Google Sheets API Credentials |
| config.googleSheets.email | string | `"myemail"` | Email to send notifications to |
| config.googleSheets.spreadsheetId | string | `"mysheetid"` | Google Sheets Spreadsheet ID |
| config.mongo.collection | string | `"mycollection"` | MongoDB Collection |
| config.mongo.database | string | `"mydb"` | MongoDB Database |
| config.mongo.host | string | `"myhost"` | MongoDB Host |
| config.openAi.apiKey | string | `"myapikey"` | OpenAI API Key |
| config.sharedSecret | string | `"mysharedsecret"` | Shared Secret |
| deploymentAnnotations | object | `{}` | Annotations to add to deployments |
| fullnameOverride | string | `""` | The full release name override |
| image.pullPolicy | string | `"Always"` | The pullPolicy used when pulling the image |
| image.repository | string | `"673156464838.dkr.ecr.us-west-2.amazonaws.com/pgt-leader-bot"` | The repository of the image |
| image.tag | string | `"0.0.1"` | Overrides the image tag whose default is the chart appVersion. |
| imagePullSecrets | list | `[]` | The secrets used to pull the image |
| ingress.annotations | object | `{}` | Ingress Annotations |
| ingress.className | string | `""` | Ingress Class Name |
| ingress.enabled | bool | `false` | Enable Ingress |
| ingress.hosts | list | `[{"host":"chart-example.local","paths":[{"path":"/","pathType":"ImplementationSpecific"}]}]` | Ingress Hosts |
| ingress.tls | list | `[]` | Ingress TLS configuration |
| lifecycle | object | `{"preStop":{"exec":{"command":["sh","-c","sleep 15 && kill -SIGQUIT 1"]}}}` | Lifecycle hooks |
| livenessProbe | string | `nil` | Liveness Probe |
| mongodb.auth.enabled | bool | `false` | Enable MongoDB Authentication |
| nameOverride | string | `""` | The release name override |
| nodeSelector | object | `{}` | Node selector labels |
| podAnnotations | object | `{}` | Annotations to add to the pods |
| podLabels | object | `{}` | Label to add to the pods |
| podSecurityContext | object | `{}` | The Pod Security Context |
| readinessProbe | string | `nil` | Readiness Probe |
| replicaCount | int | `1` | The number of replicas |
| resources | object | `{}` | The Resources |
| securityContext | object | `{}` | The Security Context |
| service.port | int | `8000` | The service port |
| service.type | string | `"ClusterIP"` | The service type |
| serviceAccount.annotations | object | `{}` | Annotations to add to the service account |
| serviceAccount.automount | bool | `true` | Automatically mount a ServiceAccount's API credentials? |
| serviceAccount.create | bool | `true` | Specifies whether a service account should be created |
| serviceAccount.name | string | `""` | The name of the service account to use. |
| tolerations | list | `[]` | Tolerations |
| volumeMounts | list | `[]` | Additional volumeMounts on the output Deployment definition. |
| volumes | list | `[]` | Additional volumes on the output Deployment definition. |

