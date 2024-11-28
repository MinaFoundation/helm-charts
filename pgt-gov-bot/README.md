# pgt-gov-bot

![Version: 0.2.0](https://img.shields.io/badge/Version-0.2.0-informational?style=flat-square) ![Type: application](https://img.shields.io/badge/Type-application-informational?style=flat-square) ![AppVersion: 1.16.0](https://img.shields.io/badge/AppVersion-1.16.0-informational?style=flat-square)

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
| bot.image.tag | string | `"0.0.21"` |  |
| bot.imagePullSecrets | list | `[]` | The secrets used to pull the image |
| bot.livenessProbe | string | `nil` | Liveness check configuration |
| bot.podAnnotations | object | `{}` | Annotations to add to the pods |
| bot.podLabels | object | `{}` | Labels to add to the pods |
| bot.readinessProbe | string | `nil` | Readiness check configuration |
| bot.replicaCount | int | `1` | The number of replicas |
| bot.resources | object | `{}` | Resource limitations for the pods |
| config.mef.frontend.baseUrl | string | `"https://example.minaprotocol.network"` |  |
| config.privateKey | string | `"-----BEGIN PRIVATE KEY-----\nMIIEvAIBADANBgkqhkiG9w0BAQEFAASCBKYwggSiAgEAAoIBAQDCEKoQMfoxAoAx\nL9aNa2YP5EIy8dgqB/bcR6jaZwBUGaxqdeaA9ofYiIcEZyqPW5hL79i+tvHKfhU+\nTgh2VLAy2bpHyJZknwzLfC1lAyx67lZeIZpV1pqgvJL08rQZpddV+42Cucx2AglD\nT25X0W/FjsIwZKfq9eiRKIa0avrd8PUM9A5NmQcVg2lsxLDR4fCqaieQSm3u1gXf\nNO8H8wfyS5ZLgXWskzjAgeJgqg49SphziV/sr9+I4YSWQxAMYsVd6wwJVcMh25Hd\notjCHCS/HFxIVAvpt2YZf/xc9qZ0KKC7EA8CfjsrzQAX1SlMbamXu6d5JeyLcI+h\n8PzJOUvVAgMBAAECggEASL/mgNu7ZtQBKm88hxdT03FGP8LZvifuKvXSHs2uGdjm\nAaLhHkdM9ad4tfXWxpcXqJ/pKNV8HuTVId4u3e0xgF6OropLlrzpFv8eJVfjPNJM\nHk2KhdNFdCw9CwZQ7ax15Q3AJtlwBG0O++SzAMjKlczGj02shTBaVtBSbyALm1co\nfRLaWjHdOUgHprbm+OG6cplGiJHkdCIf4pyo/OBt9rA/8f8mSvSTG7p3YamOAWFU\npGup1mRQmvOPjX4No2pzpEofKsZmlCYNZigABfjrUY2+Rmj0kELnxVnhoowu/ben\nNWGVeL5JhpWnfhYquzOf/N+qvGPVP0XUGM+roDGboQKBgQD96aCpkXcJMNAfevH3\nOPffLmMwLKbDu3N6xpSMiDN7rFmfzp7yxMW1mTj9juTKsHa5v7F4RQ3I1N+RNCp6\nOBgrqQC5uU7D+1P6f072xWjw5aV84JfBedkj78N97fblCVCdXXebf7TsKQAJJUWR\nb0pT+yi2Yiz0neVgBd/ER2J/gwKBgQDDqRWhHl7vMGuW0OksTbdEX2VRkOZNBjfn\nfly97e+eCccL41ghRLhGjBfDGUi6DuB6XCUdZqGZVi8Fy30V2wrsPyZ4xiypWJS/\nARMMGvM1vbG6GY0pPzDzooIm8TsXl59cLOedKrfyLhLB5Cn34X1p8kWrsQmfnecD\nnAcr1nqPxwKBgExLIsdQuh+81wxeeM38BB6/ZXZYNFOjw3MksAX59t42T0fBYek4\nTt/eBk3J3d05YLM3ci/dL+Mkc3jB3/GRYVHdGia0E4K3xegC0Ms9Teb0WeFH6tFr\nt18g7/CqzADN57chGotSuB4tw6D73gdxFThew0DqBvAJcZ6EpVPozyPZAoGAcN6j\neZR5k2XNSu0s9b/HTwvw+MKr+Bb0PPiqK26M4hAl4Pe/KUHpQ9khBA0b5Skb2bo6\nNuGzqy8KZT9j4y2++VXcraM0tGRDOoQ2Jq+NSZ0qX37J7ddkN8exaSGTwyJWbegB\nnKq9/lkRvQQQKczMekemZUr1kDyYvX5OrL1HapUCgYAM7VCohi1sFfDUov1lAc+d\na51R641gaZmlw2749k762+6J6vagu6hcWljPiHo4pA9drvVqeMsNdKcXfs1JXqnC\niTdqrpGobUM8bNVyPRXxryQIKOJ6ou8xt1pyenAhOoMTOSOllnU8/bM/VSPXXHrf\nGv61TwASbeDP/WPoCMnylw==\n"` |  |
| config.publicKey | string | `"-----BEGIN PUBLIC KEY-----\nMIIBIjANBgkqhkiG9w0BAQEFAAOCAQ8AMIIBCgKCAQEAwhCqEDH6MQKAMS/WjWtm\nD+RCMvHYKgf23Eeo2mcAVBmsanXmgPaH2IiHBGcqj1uYS+/Yvrbxyn4VPk4IdlSw\nMtm6R8iWZJ8My3wtZQMseu5WXiGaVdaaoLyS9PK0GaXXVfuNgrnMdgIJQ09uV9Fv\nxY7CMGSn6vXokSiGtGr63fD1DPQOTZkHFYNpbMSw0eHwqmonkEpt7tYF3zTvB/MH\n8kuWS4F1rJM4wIHiYKoOPUqYc4lf7K/fiOGElkMQDGLFXesMCVXDIduR3aLYwhwk\nvxxcSFQL6bdmGX/8XPamdCiguxAPAn47K80AF9UpTG2pl7uneSXsi3CPofD8yTlL\n1QIDAQAB\n-----END PUBLIC KEY-----\n"` |  |
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
| ocvWeb.image.tag | string | `"0.0.4"` |  |
| ocvWeb.imagePullSecrets | list | `[]` | The secrets used to pull the image |
| ocvWeb.livenessProbe | string | `nil` | Liveness check configuration |
| ocvWeb.podAnnotations | object | `{}` | Annotations to add to the pods |
| ocvWeb.podLabels | object | `{}` | Labels to add to the pods |
| ocvWeb.readinessProbe | string | `nil` | Readiness check configuration |
| ocvWeb.replicaCount | int | `1` | The number of replicas |
| ocvWeb.resources | object | `{}` | Resource limitations for the pods |
| ocvWeb.service.port | int | `4321` | Service port |
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

