# redisinsight

![Version: 0.1.0](https://img.shields.io/badge/Version-0.1.0-informational?style=flat-square) ![Type: application](https://img.shields.io/badge/Type-application-informational?style=flat-square) ![AppVersion: 2.48.0](https://img.shields.io/badge/AppVersion-2.48.0-informational?style=flat-square)

A Helm chart for Redisinsight

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
| fullnameOverride | string | `""` | The full release name override |
| image.pullPolicy | string | `"IfNotPresent"` | The pullPolicy used when pulling the image |
| image.repository | string | `"redis/redisinsight"` | The repository of the image |
| image.tag | string | `"latest"` | The tag of the iamge. Overrides the image tag whose default is the chart appVersion. |
| imagePullSecrets | list | `[]` | The secrets used to pull the image |
| ingress | object | `{"annotations":{},"className":"","enabled":false,"hosts":[{"host":"redisinsight.local","paths":[{"path":"/","pathType":"ImplementationSpecific"}]}],"tls":[]}` | Ingress related values |
| ingress.annotations | object | `{}` | Ingress annotations |
| ingress.className | string | `""` | IngressClass used for the ingress |
| ingress.enabled | bool | `false` | Whether to enable the ingress or not |
| ingress.tls | list | `[]` | Tls settings |
| nameOverride | string | `""` | The release name override |
| nodeSelector | object | `{}` | Node selector labels |
| persistence | object | `{"annotations":{"helm.sh/resource-policy":"keep"},"className":"","enabled":true,"size":"100Mi"}` | Presistence related values |
| persistence.annotations | object | `{"helm.sh/resource-policy":"keep"}` | Annotations for the Persistent Volume Claim |
| persistence.className | string | `""` | The name of the storageclass |
| persistence.enabled | bool | `true` | Whether to enable persistence or not |
| persistence.size | string | `"100Mi"` | Size of the Persistent Volume |
| platform | string | `"sandbox"` | The name of the environment |
| podAnnotations | object | `{}` | Annotations to add to the pods |
| podSecurityContext | object | `{"fsGroup":1000,"runAsGroup":1000,"runAsUser":1000}` | SecurityContext used for the pods |
| resources | object | `{}` | Resource limitations for the pods |
| securityContext | object | `{}` | SecurityContext |
| server.extraEnvVars | object | `{}` | Extra environment variables to inject |
| server.headless | object | `{"annotations":{},"labels":{}}` | Specific values for the headless service resource |
| server.headless.annotations | object | `{}` | Headless service annotations |
| server.headless.labels | object | `{}` | Headless service labels |
| server.ports | object | `{"ui":5540}` | Collection of ports |
| server.ports.ui | int | `5540` | Port through which the UI is exposed |
| server.replicas | int | `1` | The number of pods to be deployed for server |
| server.service | object | `{"annotations":{},"labels":{}}` | Specific values for the service resource |
| server.service.annotations | object | `{}` | Service annotations |
| server.service.labels | object | `{}` | Service labels |
| serviceAccount.create | bool | `true` | Specifies whether a service account should be created |
| serviceAccount.name | string | `""` | The name of the service account to use. If not set and create is true, a name is generated using the fullname template |
| terminationGracePeriodSeconds | int | `30` | The time to wait before terminating the process |
| tolerations | list | `[]` | Tolerations |

