# pod-rotation-controller

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
| affinity | object | `{}` | Affinity |
| fullnameOverride | string | `""` | The full release name override |
| image.pullPolicy | string | `"IfNotPresent"` | The pullPolicy used when pulling the image |
| image.repository | string | `"673156464838.dkr.ecr.us-west-2.amazonaws.com/github-actions-runner"` | The repository of the image |
| image.tag | string | `"default-2023.09.26"` | The tag of the image. |
| imagePullSecrets | list | `[]` | The secrets used to pull the image |
| nameOverride | string | `""` | The release name override |
| nodeSelector | object | `{}` | Node Selector |
| podAnnotations | object | `{}` | Annotations to add to deployments |
| podLabels | object | `{}` | Annotations to add to the pods |
| podRegexPattern | string | `".*"` | The Pod Regex Pattern |
| podSecurityContext | object | `{}` | The Pod Security Context |
| resources | object | `{"limits":{},"requests":{}}` | Resources |
| resources.limits | object | `{}` | The resources limits for the pod-rotation-controller container |
| resources.requests | object | `{}` | The resources requests for the pod-rotation-controller container |
| restartPolicy | string | `"OnFailure"` | The restart policy |
| schedule | string | `"0 */6 * * *"` | The Pod Rotation Schedule |
| securityContext | object | `{}` | The Security Context |
| serviceAccount.annotations | object | `{}` | Annotations to add to the service account |
| serviceAccount.create | bool | `true` | Create a service account |
| serviceAccount.name | string | `""` | The name of the service account to use |
| tolerations | list | `[]` | Tolerations |

