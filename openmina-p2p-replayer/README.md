# openmina-p2p-replayer

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
| extraEnvVars | object | `{}` |  |
| fullnameOverride | string | `""` | Full name override |
| image.pullPolicy | string | `"IfNotPresent"` | The image pull policy |
| image.repository | string | `"vladsimplestakingcom/bootstrap-rr"` | The image repository |
| image.tag | string | `"3.0.0-bullseye-devnet"` | Overrides the image tag whose default is the chart appVersion. |
| imagePullSecrets | list | `[]` | The secrets used to pull the image |
| livenessProbe | object | `{"initialDelaySeconds":15,"periodSeconds":10,"tcpSocket":{"port":8302}}` | Liveness check configuration |
| nameOverride | string | `""` | Name override |
| nodeSelector | object | `{}` | Node selector labels |
| podAnnotations | object | `{}` | Annotations to add to the pods |
| podLabels | object | `{}` | Label to add to the pods |
| podSecurityContext | object | `{}` | The Pod Security Context |
| readinessProbe | object | `{"initialDelaySeconds":15,"periodSeconds":10,"tcpSocket":{"port":8302}}` | Readiness check configuration |
| replayer.blockHeight | int | `328010` | The final height of the chain |
| replayer.chainId | string | `"/coda/0.0.1/29936104443aaf264a7f0192ac64b1c7173198c1ed404c1bcff5e562e05eb7f6"` | Chain ID |
| replayer.p2p.secretKey | string | `""` |  |
| replicaCount | int | `1` | The number of replicas |
| resources | object | `{}` | The Resources |
| securityContext | object | `{}` | The Security Context |
| service.port | int | `8302` | Service port |
| service.type | string | `"ClusterIP"` | Service type |
| serviceAccount.annotations | object | `{}` |  |
| serviceAccount.automount | bool | `true` | Automatically mount a ServiceAccount's API credentials? |
| serviceAccount.create | bool | `false` | Specifies whether a service account should be created |
| serviceAccount.name | string | `""` | If not set and create is true, a name is generated using the fullname template |
| tolerations | list | `[]` | The tolerations |
| volumeMounts | list | `[]` | Additional volumeMounts on the output Deployment definition. |
| volumes | list | `[]` | Additional volumes on the output Deployment definition. |

