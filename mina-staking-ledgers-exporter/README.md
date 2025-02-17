# mina-staking-ledgers-exporter

![Version: 0.1.4](https://img.shields.io/badge/Version-0.1.4-informational?style=flat-square) ![Type: application](https://img.shields.io/badge/Type-application-informational?style=flat-square) ![AppVersion: 1.16.0](https://img.shields.io/badge/AppVersion-1.16.0-informational?style=flat-square)

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
| image.repository | string | `"673156464838.dkr.ecr.us-west-2.amazonaws.com/github-actions-runner"` | The repository of the image |
| image.tag | string | `"default-2024.03"` | The tag of the image. Overrides the image tag whose default is the chart appVersion. |
| imagePullSecrets | list | `[]` | The secrets used to pull the image |
| minaStakingLedgersExporter.logLevel | string | `"info"` | The log level |
| minaStakingLedgersExporter.minaNodeLabel | string | `nil` | The Mina node label used to query the ledger |
| minaStakingLedgersExporter.minaPayoutsDataProvider.enabled | bool | `true` | Enable upload to Mina payouts data provider |
| minaStakingLedgersExporter.minaPayoutsDataProvider.password | string | `nil` | The Mina payouts data provider password |
| minaStakingLedgersExporter.minaPayoutsDataProvider.url | string | `nil` | The Mina payouts data provider URL |
| minaStakingLedgersExporter.minaPayoutsDataProvider.username | string | `nil` | The Mina payouts data provider username |
| minaStakingLedgersExporter.network | string | `nil` | The network (mainnet | devnet) |
| minaStakingLedgersExporter.s3.bucket | string | `nil` | The S3 bucket |
| minaStakingLedgersExporter.s3.enabled | bool | `true` | Enable upload to S3 |
| minaStakingLedgersExporter.s3.subpath | string | `nil` | The S3 subpath |
| minaStakingLedgersExporter.slackWebhookInfoUrl | string | `nil` | The Slack webhook URL for info messages |
| minaStakingLedgersExporter.slackWebhookWarnUrl | string | `nil` | The Slack webhook URL for warn messages |
| nameOverride | string | `""` | The release name override |
| nodeSelector | object | `{}` | Node selector labels |
| podAnnotations | object | `{}` | Annotations to add to the pods |
| podSecurityContext | object | `{}` | The Pod Security Context |
| resources | object | `{}` | Resource limitations for the pods |
| restartPolicy | string | `"Never"` | The restart policy |
| schedule | string | `"0 0 * * *"` | The cronjob schedule |
| securityContext | object | `{}` | The Security Context |
| serviceAccount.annotations | object | `{}` | Annotations to add to the service account |
| serviceAccount.create | bool | `true` | Specifies whether a service account should be created |
| serviceAccount.name | string | `""` | The name of the service account to use. |
| tolerations | list | `[]` | Tolerations |

