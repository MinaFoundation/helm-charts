# minametrix

![Version: 0.1.2](https://img.shields.io/badge/Version-0.1.2-informational?style=flat-square) ![Type: application](https://img.shields.io/badge/Type-application-informational?style=flat-square) ![AppVersion: 1.16.0](https://img.shields.io/badge/AppVersion-1.16.0-informational?style=flat-square)

A Helm chart for Kubernetes

## Requirements

| Repository | Name | Version |
|------------|------|---------|
| oci://registry-1.docker.io/bitnamicharts | mongodb | * |

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
| admin_password | string | `"minametrix"` | Admin Password |
| affinity | object | `{}` | Affinity rules |
| api_tokens | string | `""` | API Tokens |
| extraEnvVars | object | `{}` | Extra environment variables |
| fullnameOverride | string | `""` | The full release name override |
| global.imageRegistry | string | `"docker.io"` | Global Docker image registry |
| image.pullPolicy | string | `"IfNotPresent"` | The pullPolicy used when pulling the image |
| image.repository | string | `"673156464838.dkr.ecr.us-west-2.amazonaws.com/minametrix"` | The repository of the image |
| image.tag | string | `"1.0.0-aec2116"` | Overrides the image tag whose default is the chart appVersion. |
| imagePullSecrets | list | `[]` | The secrets used to pull the image |
| ingress.annotations | object | `{}` | Ingress Annotations |
| ingress.className | string | `""` | Ingress Class Name |
| ingress.enabled | bool | `false` | Enable Ingress |
| ingress.hosts | list | `[{"host":"chart-example.local","paths":[{"path":"/","pathType":"ImplementationSpecific"}]}]` | Ingress Hosts |
| ingress.tls | list | `[]` | TLS configuration |
| is_local | bool | `false` | Is Local |
| mongo_connection_string | string | `""` | Mongo Connection String |
| mongodb.enabled | bool | `true` | Enable MongoDB |
| nameOverride | string | `""` | The release name override |
| nodeSelector | object | `{}` | Node selector labels |
| persistence.accessMode | string | `"ReadWriteOnce"` | The access mode of the Persistent Volume Claim |
| persistence.annotations | object | `{}` | Annotations to add to the Persistent Volume Claim |
| persistence.enabled | bool | `true` | Enable persistence using Persistent Volume Claims |
| persistence.size | string | `"1Gi"` | The size of the Persistent Volume Claim |
| persistence.storageClass | string | `"ebs-gp3-encrypted"` | The storage class of the Persistent Volume Claim |
| podAnnotations | object | `{}` | Annotations to add to the pods |
| podSecurityContext | object | `{}` | The Pod Security Context |
| previous_search_timestamp | string | `"1697711276493"` | Previous Search Timestamps |
| replicaCount | int | `1` | The number of replicas |
| resources | object | `{}` | Resource limitations for the pods |
| search_timestamp | string | `"1697711276493"` | Search Timestamps |
| securityContext | object | `{}` | Security Context |
| service.port | int | `3000` | The service port |
| service.type | string | `"ClusterIP"` | The service type |
| serviceAccount.annotations | object | `{}` | Annotations to add to the service account |
| serviceAccount.create | bool | `true` | Specifies whether a service account should be created |
| serviceAccount.name | string | `""` | The name of the service account to use. |
| session_secret | string | `"minametrix"` | Session Secret |
| tolerations | list | `[]` | Tolerations |
| web_concurency | int | `2` | Web Concurrency |

