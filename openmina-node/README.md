# openmina-node

![Version: 0.1.1](https://img.shields.io/badge/Version-0.1.1-informational?style=flat-square) ![Type: application](https://img.shields.io/badge/Type-application-informational?style=flat-square) ![AppVersion: v0.8.1](https://img.shields.io/badge/AppVersion-v0.8.1-informational?style=flat-square)

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
| deploymentAnnotations | object | `{}` | Annotations to add to deployments |
| fullnameOverride | string | `""` | The full release name override |
| image.pullPolicy | string | `"IfNotPresent"` | The pullPolicy used when pulling the image |
| image.repository | string | `"openmina/openmina"` | The image repository |
| image.tag | string | `"0.11.2"` | Overrides the image tag whose default is the chart appVersion. |
| imagePullSecrets | list | `[]` | The secrets used to pull the image |
| ingress.annotations | object | `{}` | The Ingress Annotations |
| ingress.className | string | `""` | The Ingress Class Name to use |
| ingress.enabled | bool | `false` | Whether to create an Ingress |
| ingress.hosts | list | `[{"host":"chart-example.local","paths":[{"path":"/","pathType":"ImplementationSpecific"}]}]` | The Ingress Hosts |
| ingress.tls | list | `[]` | The TLS configuration |
| livenessProbe | string | `nil` | Liveness check configuration |
| nameOverride | string | `""` | The release name override |
| node.args | list | `[]` | The arguments to pass at runtime |
| node.envVars | object | `{}` | The environment variables to set |
| node.homeDirectory | string | `"/root/.openmina"` | The home directory of the node |
| node.libp2p.discoveryExternalIp | object | `{"enabled":false,"targetDNS":"example.nlb.us-west-2.amazonaws.com"}` | Discovery External IP |
| node.libp2p.discoveryExternalIp.enabled | bool | `false` | Enable Discovery External IP |
| node.libp2p.discoveryExternalIp.targetDNS | string | `"example.nlb.us-west-2.amazonaws.com"` | Target DNS |
| node.libp2p.port | int | `8302` | The libp2p peer id |
| node.libp2p.privateKey | string | `""` | The libp2p private key |
| node.libp2p.publicKey | string | `""` | The libp2p public key |
| node.wallet.privateKey | string | `""` | The wallet private key |
| node.wallet.publicKey | string | `""` | The wallet public key |
| nodeSelector | object | `{}` | Node selector labels |
| persistence.accessMode | string | `"ReadWriteOnce"` | The access mode of the PVC |
| persistence.annotations | object | `{}` | Annotations to add to the PVC |
| persistence.enabled | bool | `true` | Enable persistence using PVC |
| persistence.size | string | `"1Gi"` | The size of the PVC |
| persistence.storageClass | string | `"ebs-gp3-encrypted"` | The StorageClass of the PVC |
| podAnnotations | object | `{}` | Annotations to add to the pods |
| podLabels | object | `{}` | Label to add to the pods |
| podSecurityContext | object | `{}` | The Pod Security Context |
| readinessProbe | string | `nil` | Readiness check configuration |
| replicaCount | int | `1` | The number of replicas |
| resources | object | `{}` | Resource limitations for the pods |
| securityContext | object | `{}` | The Security Context |
| service.port | int | `3000` | The service port |
| service.type | string | `"ClusterIP"` | The service type |
| serviceAccount.annotations | object | `{}` | Annotations to add to the service account |
| serviceAccount.automount | bool | `true` | Automatically mount a ServiceAccount's API credentials? |
| serviceAccount.create | bool | `true` | Specifies whether a service account should be created |
| serviceAccount.name | string | `""` | The name of the service account to use. |
| tolerations | list | `[]` | Tolerations |
| volumeMounts | list | `[]` | Additional volumeMounts on the output Deployment definition. |
| volumes | list | `[]` | Additional volumes on the output Deployment definition. |

