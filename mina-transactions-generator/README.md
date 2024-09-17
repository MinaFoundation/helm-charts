# mina-transactions-generator

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
| generator.extraEnvVars | list | `[]` | Extra Environment Variables |
| generator.minaGraphqlUrl | string | `"http://localhost:3085/graphql"` | The graphql URL to send transactions to |
| generator.networkProfile | string | `"testnet"` | The Network Profile to use (accepted values are: mainnet, testnet) |
| generator.recipientWalletList | list | `[]` | The list of recipient wallets |
| generator.senderPrivateKey | string | `""` | The private key of the sender |
| generator.transaction.amount | int | `2` | The amount of the transaction |
| generator.transaction.fee | float | `0.1` | The fee of the transaction |
| generator.transaction.interval | int | `5000` | The interval in milliseconds between each transaction |
| generator.transaction.type | string | `"mixed"` | The type of transaction to send (accepted values are: regular, zkApp, mixed) |
| image.pullPolicy | string | `"IfNotPresent"` | The pullPolicy used when pulling the image |
| image.repository | string | `"673156464838.dkr.ecr.us-west-2.amazonaws.com/mina-transactions-generator"` | The repository of the image |
| image.tag | string | `"0.2.3-fb4474e"` | The tag of the image. Overrides the image tag whose default is the chart appVersion. |
| imagePullSecrets | list | `[]` | The secrets used to pull the image |
| nameOverride | string | `""` | The release name override |
| nodeSelector | object | `{}` | Node selector labels |
| podAnnotations | object | `{}` | Annotations to add to the pods |
| podLabels | object | `{}` | The labels to add to the pods |
| podSecurityContext | object | `{}` | The Pod Security Context |
| replicaCount | int | `1` | The number of replicas |
| resources | object | `{"limits":{"cpu":1,"memory":"512Mi"},"requests":{"cpu":"500m","memory":"256Mi"}}` | Resource limitations for the pods |
| securityContext | object | `{}` | The Security Context |
| serviceAccount.annotations | object | `{}` | Annotations to add to the service account |
| serviceAccount.automount | bool | `true` | Automatically mount a ServiceAccount's API credentials? |
| serviceAccount.create | bool | `true` | Specifies whether a service account should be created |
| serviceAccount.name | string | `""` | The name of the service account to use. |
| tolerations | list | `[]` | Tolerations |

