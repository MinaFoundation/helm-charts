# matterbridge-bot

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
| affinity | object | `{}` | Affinity rules |
| fullnameOverride | string | `""` | The full release name override |
| image.pullPolicy | string | `"IfNotPresent"` | The pullPolicy used when pulling the image |
| image.repository | string | `"42wim/matterbridge"` | The repository of the image |
| image.tag | string | `"latest"` | The tag of the image. Overrides the image tag whose default is the chart appVersion. |
| imagePullSecrets | list | `[]` | The secrets used to pull the image |
| matterbridge.configTomlBase64 | string | `""` | The configuration file for matterbridge in base64 format |
| nameOverride | string | `""` | The release name override |
| nodeSelector | object | `{}` | Node selector labels |
| podAnnotations | object | `{}` | Annotations to add to the pods |
| podLabels | object | `{}` | The labels to add to the pods |
| podSecurityContext | object | `{}` | The Pod Security Context |
| replicaCount | int | `1` | The number of replicas |
| resources | object | `{"limits":{"cpu":"100m","memory":"128Mi"},"requests":{"cpu":"100m","memory":"128Mi"}}` | Resource limitations for the pods |
| securityContext | object | `{}` | The Security Context |
| serviceAccount.annotations | object | `{}` | Annotations to add to the service account |
| serviceAccount.automount | bool | `true` | Automatically mount a ServiceAccount's API credentials? |
| serviceAccount.create | bool | `true` | Specifies whether a service account should be created |
| serviceAccount.name | string | `""` | If not set and create is true, a name is generated using the fullname template |
| tolerations | list | `[]` | Tolerations |
| volumeMounts | list | `[]` | Additional volumeMounts on the output Deployment definition. |
| volumes | list | `[]` | Additional volumes on the output Deployment definition. |
