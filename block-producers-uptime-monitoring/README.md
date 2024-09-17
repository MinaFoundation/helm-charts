# block-producers-uptime-monitoring

![Version: 0.1.0](https://img.shields.io/badge/Version-0.1.0-informational?style=flat-square) ![Type: application](https://img.shields.io/badge/Type-application-informational?style=flat-square) ![AppVersion: 0.1.0](https://img.shields.io/badge/AppVersion-0.1.0-informational?style=flat-square)

Custom monitoring tool for Block Producers Uptime

## Source Code

* <https://github.com/MinaProtocol/mf-devops-workflows/tree/main/docker-image-ecr/bpu-monitoring>

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
| deployment.affinity | object | `{}` | The affinity for the pod assignment |
| deployment.env.network | string | `"mainnet"` | Network |
| deployment.env.timeBefore | string | `"20"` | Time before |
| deployment.image.pullPolicy | string | `"IfNotPresent"` | The image pull policy |
| deployment.image.repository | string | `"673156464838.dkr.ecr.us-west-2.amazonaws.com/block-producers-uptime-monitoring"` | The image repository |
| deployment.image.tag | string | `"1.0.0-82c48e5-bullseye-mainnet"` | Overrides the image tag |
| deployment.podAffinityPreset | string | `""` | The affinity for the pod assignment |
| deployment.podAntiAffinityPreset | string | `"soft"` | The node anti-affinity for the pod assignment |
| deployment.replicaCount | int | `1` | The number of replicas |
| resources.cpuLimit | string | `"1"` | The cpu limit |
| resources.cpuRequest | string | `"500m"` | The cpu request |
| resources.memoryLimit | string | `"512Mi"` | The memory limit |
| resources.memoryRequest | string | `"256Mi"` | The memory request |

