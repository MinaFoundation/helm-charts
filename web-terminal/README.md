# web-terminal

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
| affinity | object | `{}` |  |
| autoscaling.enabled | bool | `false` |  |
| autoscaling.maxReplicas | int | `100` |  |
| autoscaling.minReplicas | int | `1` |  |
| autoscaling.targetCPUUtilizationPercentage | int | `80` |  |
| basicAuth.password | string | `"sR2vr!65D*0LzA"` |  |
| basicAuth.user | string | `"super-mina-admin"` |  |
| bootstrapCommands | string | `"apk add --quiet --no-progress curl ttyd aws-cli kubectl bash tar\nSTERN_VERSION=$(curl -s https://api.github.com/repos/stern/stern/releases/latest | grep 'tag_name' | cut -d '\"' -f 4)\ncurl -LO https://github.com/stern/stern/releases/download/${STERN_VERSION}/stern_${STERN_VERSION#v}_linux_amd64.tar.gz\ntar -xvzf stern_${STERN_VERSION#v}_linux_amd64.tar.gz && mv stern /usr/local/bin/ && chmod +x /usr/local/bin/stern\n"` |  |
| command | string | `"bash -c \"echo hello world\""` |  |
| fullnameOverride | string | `""` |  |
| image.pullPolicy | string | `"IfNotPresent"` |  |
| image.repository | string | `"alpine"` |  |
| image.tag | string | `"latest"` |  |
| imagePullSecrets | list | `[]` |  |
| ingress.annotations | object | `{}` |  |
| ingress.className | string | `""` |  |
| ingress.enabled | bool | `false` |  |
| ingress.hosts[0].host | string | `"chart-example.local"` |  |
| ingress.hosts[0].paths[0].path | string | `"/"` |  |
| ingress.hosts[0].paths[0].pathType | string | `"ImplementationSpecific"` |  |
| ingress.tls | list | `[]` |  |
| livenessProbe.tcpSocket.port | int | `80` |  |
| nameOverride | string | `""` |  |
| nodeSelector | object | `{}` |  |
| podAnnotations | object | `{}` |  |
| podLabels | object | `{}` |  |
| podSecurityContext | object | `{}` |  |
| readinessProbe.tcpSocket.port | int | `80` |  |
| readonly | bool | `true` |  |
| replicaCount | int | `1` |  |
| resources | object | `{}` |  |
| roleRules[0].apiGroups[0] | string | `""` |  |
| roleRules[0].resources[0] | string | `"pods"` |  |
| roleRules[0].verbs[0] | string | `"get"` |  |
| roleRules[0].verbs[1] | string | `"watch"` |  |
| roleRules[0].verbs[2] | string | `"list"` |  |
| roleRules[1].apiGroups[0] | string | `""` |  |
| roleRules[1].resources[0] | string | `"pods/log"` |  |
| roleRules[1].verbs[0] | string | `"get"` |  |
| securityContext | object | `{}` |  |
| service.port | int | `80` |  |
| service.type | string | `"ClusterIP"` |  |
| serviceAccount.annotations | object | `{}` |  |
| serviceAccount.automount | bool | `true` |  |
| serviceAccount.create | bool | `true` |  |
| serviceAccount.name | string | `""` |  |
| tolerations | list | `[]` |  |
| volumeMounts | list | `[]` |  |
| volumes | list | `[]` |  |

