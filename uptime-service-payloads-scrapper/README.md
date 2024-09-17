# uptime-service-payloads-scrapper

![Version: 0.1.0](https://img.shields.io/badge/Version-0.1.0-informational?style=flat-square) ![Type: application](https://img.shields.io/badge/Type-application-informational?style=flat-square) ![AppVersion: 1.0.0](https://img.shields.io/badge/AppVersion-1.0.0-informational?style=flat-square)

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
| affinity | object | `{}` | Affinity |
| autoscaling.enabled | bool | `false` | Whether to enable autoscaling |
| autoscaling.maxReplicas | int | `5` | The maximum number of pods |
| autoscaling.minReplicas | int | `1` | The minimum number of pods |
| autoscaling.targetCPUUtilizationPercentage | int | `80` | The target CPU utilization percentage |
| fullnameOverride | string | `""` | The full release name override |
| image.pullPolicy | string | `"IfNotPresent"` | The image pull policy |
| image.repository | string | `"673156464838.dkr.ecr.us-west-2.amazonaws.com/uptime-service-payloads-scrapper"` | The image repository |
| image.tag | string | `"1.0.0-6e0b3ec"` | Overrides the image tag whose default is the chart appVersion. |
| imagePullSecrets | list | `[]` | The secrets used to pull the image |
| ingress.annotations | object | `{}` | Ingress Annotations |
| ingress.className | string | `""` | Ingress class name |
| ingress.enabled | bool | `false` | Whether to enable ingress |
| ingress.hosts | list | `[{"host":"chart-example.local","paths":[{"path":"/","pathType":"ImplementationSpecific"}]}]` | Ingress hosts |
| ingress.tls | list | `[]` | Ingress TLS configuration |
| nameOverride | string | `""` | The release name override |
| nodeSelector | object | `{}` | Node selector |
| persistence.accessMode | string | `"ReadWriteOnce"` | The access mode |
| persistence.annotations | object | `{}` | Annotations to add to the PVC |
| persistence.enabled | bool | `false` | Whether to enable persistence |
| persistence.size | string | `"10Gi"` | The size of the PVC |
| persistence.storageClass | string | `"ebs-gp3-encrypted"` | The storage class |
| podAnnotations | object | `{}` | Annotations to add to the pods |
| podSecurityContext | object | `{}` | Pods Security Context |
| replicaCount | int | `1` | The number of replicas |
| resources | object | `{}` | Resources |
| securityContext | object | `{}` | Security Context |
| service.port | int | `8080` | The service port |
| service.type | string | `"ClusterIP"` | The service type |
| serviceAccount.annotations | object | `{}` | Annotations to add to the service account |
| serviceAccount.create | bool | `true` | Specifies whether a service account should be created |
| serviceAccount.name | string | `""` | The name of the service account to use. |
| tolerations | list | `[]` | Tolerations |

