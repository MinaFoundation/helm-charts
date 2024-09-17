# openmina-block-producer-dashboard

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
| affinity | object | `{}` | The affinity |
| args | list | `[]` | The arguments to pass at runtime |
| autoscaling.enabled | bool | `false` | Enable autoscaling for the deployment |
| autoscaling.maxReplicas | int | `100` | The maximum number of pods |
| autoscaling.minReplicas | int | `1` | The minimum number of pods |
| autoscaling.targetCPUUtilizationPercentage | int | `80` | The target CPU utilization percentage |
| deploymentAnnotations | object | `{}` | Annotations to add to deployments |
| envVars | object | `{}` |  |
| fullnameOverride | string | `""` | Full name override |
| image.pullPolicy | string | `"IfNotPresent"` | The image pull policy |
| image.repository | string | `"adrnagy/openmina-producer-dashboard"` | The image repository |
| image.tag | string | `"cluster-rc5"` | Overrides the image tag whose default is the chart appVersion. |
| imagePullSecrets | list | `[]` | The secrets used to pull the image |
| ingress.annotations | object | `{}` | The Ingress Annotations |
| ingress.className | string | `""` | The Ingress Class Name to use |
| ingress.enabled | bool | `false` | The ingress |
| ingress.hosts | list | `[{"host":"chart-example.local","paths":[{"path":"/","pathType":"ImplementationSpecific"}]}]` | The Ingress Hosts |
| ingress.tls | list | `[]` | The Ingress TLS configuration |
| livenessProbe | string | `nil` | The arguments to pass at runtime |
| nameOverride | string | `""` | Name override |
| node.wallet.privateKey | string | `""` | The wallet private key |
| node.wallet.publicKey | string | `""` | The wallet public key |
| nodeSelector | object | `{}` | The node selector |
| persistence.accessMode | string | `"ReadWriteOnce"` | The access mode of the PVC |
| persistence.annotations | object | `{}` | Annotations to add to the PVC |
| persistence.enabled | bool | `true` | Enable persistence using PVC |
| persistence.size | string | `"1Gi"` | The size of the PVC |
| persistence.storageClass | string | `"ebs-gp3-encrypted"` | The StorageClass of the PVC |
| podAnnotations | object | `{}` | Annotations to add to the pods |
| podLabels | object | `{}` | Label to add to the pods |
| podSecurityContext | object | `{}` | The Pod Security Context |
| readinessProbe | string | `nil` | The environment variables to set |
| replicaCount | int | `1` | The number of replicas |
| resources | object | `{}` | The Resources |
| securityContext | object | `{}` | The Security Context |
| service.port | int | `3000` | The service port |
| service.type | string | `"ClusterIP"` | The service |
| serviceAccount.annotations | object | `{}` |  |
| serviceAccount.automount | bool | `true` | Automatically mount a ServiceAccount's API credentials? |
| serviceAccount.create | bool | `true` | Specifies whether a service account should be created |
| serviceAccount.name | string | `""` | The name of the service account to use. |
| tolerations | list | `[]` | The tolerations |
| volumeMounts | list | `[]` | Additional volumeMounts on the output Deployment definition. |
| volumes | list | `[]` | Additional volumes on the output Deployment definition. |

