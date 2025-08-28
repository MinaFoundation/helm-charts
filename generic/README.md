# generic

![Version: 1.0.7](https://img.shields.io/badge/Version-1.0.7-informational?style=flat-square) ![Type: application](https://img.shields.io/badge/Type-application-informational?style=flat-square) ![AppVersion: 1.0.0](https://img.shields.io/badge/AppVersion-1.0.0-informational?style=flat-square)

A generic Helm chart for deploying containerized applications with support for both Deployment and StatefulSet workloads

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
| affinity | object | `{}` | Affinity for pod assignment |
| args | list | `[]` | The arguments to pass at runtime |
| autoscaling.behavior | object | `{"scaleDown":{},"scaleUp":{}}` | HPA behavior configuration |
| autoscaling.behavior.scaleDown | object | `{}` | Scale down behavior configuration |
| autoscaling.behavior.scaleUp | object | `{}` | Scale up behavior configuration |
| autoscaling.enabled | bool | `false` | Whether to enable autoscaling |
| autoscaling.maxReplicas | int | `100` | The maximum number of pods |
| autoscaling.minReplicas | int | `1` | The minimum number of pods |
| autoscaling.targetCPUUtilizationPercentage | int | `80` | The metrics to use for autoscaling |
| command | list | `[]` | The command to pass at runtime |
| deploymentAnnotations | object | `{}` | Annotations to add to deployments |
| envVars | object | `{}` |  |
| extraContainers | list | `[]` | Extra containers to run alongside the main container (sidecar containers) |
| extraObjects | list | `[]` | Extra Kubernetes objects to deploy |
| fullnameOverride | string | `""` | The full release name override |
| image.pullPolicy | string | `"IfNotPresent"` | The image pull policy |
| image.repository | string | `"nginx"` | The image repository |
| image.tag | string | `""` | Overrides the image tag whose default is the chart appVersion. |
| imagePullSecrets | list | `[]` | The secrets used to pull the image |
| ingress.annotations | object | `{}` | Ingress Annotations |
| ingress.className | string | `""` | Ingress Class Name |
| ingress.enabled | bool | `false` | Enable Ingress |
| ingress.hosts[0].host | string | `"chart-example.local"` |  |
| ingress.hosts[0].paths[0].path | string | `"/"` |  |
| ingress.hosts[0].paths[0].pathType | string | `"ImplementationSpecific"` |  |
| ingress.tls | list | `[]` | TLS configuration |
| lifecycle | object | `{"preStop":{"exec":{"command":["sh","-c","sleep 15 && kill -3 1"]}}}` | Lifecycle hooks |
| livenessProbe | object | `{"httpGet":{"path":"/_/health","port":"http"}}` | Live and Readiness Probes |
| nameOverride | string | `""` | The release name override |
| nodeSelector | object | `{}` | Node selector labels |
| podAnnotations | object | `{}` | Annotations to add to the pods |
| podLabels | object | `{}` | Label to add to the pods |
| podSecurityContext | object | `{}` | The Pod Security Context |
| readinessProbe.httpGet.path | string | `"/_/health"` |  |
| readinessProbe.httpGet.port | string | `"http"` |  |
| replicaCount | int | `1` | Replica count |
| resources | object | `{}` | The Resources |
| secrets | list | `[]` | Secrets configuration |
| securityContext | object | `{}` | The Security Context |
| service.port | int | `80` | The service port |
| service.sessionAffinity.enabled | bool | `false` | Whether to enable session affinity |
| service.sessionAffinity.timeoutSeconds | int | `10800` | The session affinity timeout in seconds |
| service.sessionAffinity.type | string | `"ClientIP"` | The session affinity type |
| service.type | string | `"ClusterIP"` | The service type |
| serviceAccount.annotations | object | `{}` | Annotations to add to the service account |
| serviceAccount.automount | bool | `true` | Automatically mount a ServiceAccount's API credentials? |
| serviceAccount.create | bool | `true` | Specifies whether a service account should be created |
| serviceAccount.name | string | `""` | The name of the service account to use. |
| serviceMonitor | object | `{"annotations":{},"enabled":false,"endpoints":[]}` | ServiceMonitor configuration for Prometheus monitoring |
| serviceMonitor.annotations | object | `{}` | ServiceMonitor annotations |
| serviceMonitor.enabled | bool | `false` | Whether to enable ServiceMonitor |
| serviceMonitor.endpoints | list | `[]` | ServiceMonitor endpoints configuration |
| tolerations | list | `[]` | Tolerations for pod assignment |
| type | string | `"deployment"` | The type of workload to deploy. Can be 'deployment' or 'statefulset'. |
| volumeMounts | list | `[]` | Additional volumeMounts on the output Deployment definition. |
| volumes | list | `[]` | Additional volumes on the output Deployment definition. |

