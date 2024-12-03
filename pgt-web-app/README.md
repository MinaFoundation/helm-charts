# pgt-web-app

![Version: 0.2.0](https://img.shields.io/badge/Version-0.2.0-informational?style=flat-square) ![Type: application](https://img.shields.io/badge/Type-application-informational?style=flat-square) ![AppVersion: 1.16.0](https://img.shields.io/badge/AppVersion-1.16.0-informational?style=flat-square)

A Helm chart for Kubernetes

## Requirements

| Repository | Name | Version |
|------------|------|---------|
| https://charts.bitnami.com/bitnami | postgresql | * |
| https://helm.runix.net | pgadmin4 | * |

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
| affinity | object | `{}` |  |
| autoscaling.enabled | bool | `false` |  |
| autoscaling.maxReplicas | int | `100` |  |
| autoscaling.minReplicas | int | `1` |  |
| autoscaling.targetCPUUtilizationPercentage | int | `80` |  |
| config.discord.clientId | string | `""` | Discord Application ID |
| config.discord.guildId | string | `""` | Discord Guild/Server ID |
| config.discord.token | string | `""` | Discord API Token |
| config.privateKey | string | `"-----BEGIN PRIVATE KEY-----\nMIIEvAIBADANBgkqhkiG9w0BAQEFAASCBKYwggSiAgEAAoIBAQDCEKoQMfoxAoAx\nL9aNa2YP5EIy8dgqB/bcR6jaZwBUGaxqdeaA9ofYiIcEZyqPW5hL79i+tvHKfhU+\nTgh2VLAy2bpHyJZknwzLfC1lAyx67lZeIZpV1pqgvJL08rQZpddV+42Cucx2AglD\nT25X0W/FjsIwZKfq9eiRKIa0avrd8PUM9A5NmQcVg2lsxLDR4fCqaieQSm3u1gXf\nNO8H8wfyS5ZLgXWskzjAgeJgqg49SphziV/sr9+I4YSWQxAMYsVd6wwJVcMh25Hd\notjCHCS/HFxIVAvpt2YZf/xc9qZ0KKC7EA8CfjsrzQAX1SlMbamXu6d5JeyLcI+h\n8PzJOUvVAgMBAAECggEASL/mgNu7ZtQBKm88hxdT03FGP8LZvifuKvXSHs2uGdjm\nAaLhHkdM9ad4tfXWxpcXqJ/pKNV8HuTVId4u3e0xgF6OropLlrzpFv8eJVfjPNJM\nHk2KhdNFdCw9CwZQ7ax15Q3AJtlwBG0O++SzAMjKlczGj02shTBaVtBSbyALm1co\nfRLaWjHdOUgHprbm+OG6cplGiJHkdCIf4pyo/OBt9rA/8f8mSvSTG7p3YamOAWFU\npGup1mRQmvOPjX4No2pzpEofKsZmlCYNZigABfjrUY2+Rmj0kELnxVnhoowu/ben\nNWGVeL5JhpWnfhYquzOf/N+qvGPVP0XUGM+roDGboQKBgQD96aCpkXcJMNAfevH3\nOPffLmMwLKbDu3N6xpSMiDN7rFmfzp7yxMW1mTj9juTKsHa5v7F4RQ3I1N+RNCp6\nOBgrqQC5uU7D+1P6f072xWjw5aV84JfBedkj78N97fblCVCdXXebf7TsKQAJJUWR\nb0pT+yi2Yiz0neVgBd/ER2J/gwKBgQDDqRWhHl7vMGuW0OksTbdEX2VRkOZNBjfn\nfly97e+eCccL41ghRLhGjBfDGUi6DuB6XCUdZqGZVi8Fy30V2wrsPyZ4xiypWJS/\nARMMGvM1vbG6GY0pPzDzooIm8TsXl59cLOedKrfyLhLB5Cn34X1p8kWrsQmfnecD\nnAcr1nqPxwKBgExLIsdQuh+81wxeeM38BB6/ZXZYNFOjw3MksAX59t42T0fBYek4\nTt/eBk3J3d05YLM3ci/dL+Mkc3jB3/GRYVHdGia0E4K3xegC0Ms9Teb0WeFH6tFr\nt18g7/CqzADN57chGotSuB4tw6D73gdxFThew0DqBvAJcZ6EpVPozyPZAoGAcN6j\neZR5k2XNSu0s9b/HTwvw+MKr+Bb0PPiqK26M4hAl4Pe/KUHpQ9khBA0b5Skb2bo6\nNuGzqy8KZT9j4y2++VXcraM0tGRDOoQ2Jq+NSZ0qX37J7ddkN8exaSGTwyJWbegB\nnKq9/lkRvQQQKczMekemZUr1kDyYvX5OrL1HapUCgYAM7VCohi1sFfDUov1lAc+d\na51R641gaZmlw2749k762+6J6vagu6hcWljPiHo4pA9drvVqeMsNdKcXfs1JXqnC\niTdqrpGobUM8bNVyPRXxryQIKOJ6ou8xt1pyenAhOoMTOSOllnU8/bM/VSPXXHrf\nGv61TwASbeDP/WPoCMnylw==\n"` |  |
| config.publicKey | string | `"-----BEGIN PUBLIC KEY-----\nMIIBIjANBgkqhkiG9w0BAQEFAAOCAQ8AMIIBCgKCAQEAwhCqEDH6MQKAMS/WjWtm\nD+RCMvHYKgf23Eeo2mcAVBmsanXmgPaH2IiHBGcqj1uYS+/Yvrbxyn4VPk4IdlSw\nMtm6R8iWZJ8My3wtZQMseu5WXiGaVdaaoLyS9PK0GaXXVfuNgrnMdgIJQ09uV9Fv\nxY7CMGSn6vXokSiGtGr63fD1DPQOTZkHFYNpbMSw0eHwqmonkEpt7tYF3zTvB/MH\n8kuWS4F1rJM4wIHiYKoOPUqYc4lf7K/fiOGElkMQDGLFXesMCVXDIduR3aLYwhwk\nvxxcSFQL6bdmGX/8XPamdCiguxAPAn47K80AF9UpTG2pl7uneSXsi3CPofD8yTlL\n1QIDAQAB\n-----END PUBLIC KEY-----\n"` |  |
| deploymentAnnotations | object | `{}` | Annotations to add to deployments |
| fullnameOverride | string | `""` |  |
| image.pullPolicy | string | `"IfNotPresent"` |  |
| image.repository | string | `"673156464838.dkr.ecr.us-west-2.amazonaws.com/pgt-web-app"` |  |
| image.tag | string | `"0.1.0"` |  |
| imagePullSecrets | list | `[]` |  |
| ingress.annotations | object | `{}` |  |
| ingress.className | string | `""` |  |
| ingress.enabled | bool | `false` |  |
| ingress.hosts[0].host | string | `"chart-example.local"` |  |
| ingress.hosts[0].paths[0].path | string | `"/"` |  |
| ingress.hosts[0].paths[0].pathType | string | `"ImplementationSpecific"` |  |
| ingress.tls | list | `[]` |  |
| livenessProbe.httpGet.path | string | `"/"` |  |
| livenessProbe.httpGet.port | string | `"http"` |  |
| nameOverride | string | `""` |  |
| nodeSelector | object | `{}` |  |
| pgadmin4.enabled | bool | `false` |  |
| podAnnotations | object | `{}` |  |
| podLabels | object | `{}` |  |
| podSecurityContext | object | `{}` |  |
| postgresql.auth.enablePostgresUser | bool | `false` | Enable the default postgres user |
| postgresql.auth.password | string | `"mina123"` | Password for the database |
| postgresql.auth.username | string | `"govbot"` | Username for the database |
| postgresql.enabled | bool | `true` | Enable local postgresql database server |
| postgresql.primary.persistence.enabled | bool | `true` | Enable the persistence for the postgresql server |
| postgresql.primary.persistence.size | string | `"8Gi"` | Size of the postgresql server volume |
| postgresql.primary.persistence.storageClass | string | `""` | Storage class for the postgresql server volume |
| postgresql.primary.resourcesPreset | string | `"nano"` | Resources preset to set resource requests and limits |
| readinessProbe.httpGet.path | string | `"/"` |  |
| readinessProbe.httpGet.port | string | `"http"` |  |
| replicaCount | int | `1` |  |
| resources | object | `{}` |  |
| securityContext | object | `{}` |  |
| service.port | int | `3000` |  |
| service.type | string | `"ClusterIP"` |  |
| serviceAccount.annotations | object | `{}` |  |
| serviceAccount.automount | bool | `true` |  |
| serviceAccount.create | bool | `true` |  |
| serviceAccount.name | string | `""` |  |
| tolerations | list | `[]` |  |
| volumeMounts | list | `[]` |  |
| volumes | list | `[]` |  |

