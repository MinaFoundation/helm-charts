# mina-rosetta

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
| image.pullPolicy | string | `"IfNotPresent"` | The image pull policy |
| image.repository | string | `"gcr.io/o1labs-192920/mina-rosetta"` | The image repository |
| image.tag | string | `"2.0.0rampup8-81d994d-focal"` | The image tag |
| imagePullSecrets | list | `[]` | The secrets used to pull the image |
| ingress.annotations | object | `{}` | Ingress Annotations |
| ingress.className | string | `""` | Ingress Class Name |
| ingress.enabled | bool | `false` | Enable Ingress |
| ingress.hosts | list | `[{"host":"chart-example.local","paths":[{"path":"/","pathType":"ImplementationSpecific"}]}]` | Ingress Hosts |
| ingress.tls | list | `[]` | The TLS configuration |
| nameOverride | string | `""` | The release name override |
| nodeSelector | object | `{}` | Node selector labels |
| podAnnotations | object | `{}` | Annotations to add to the pods |
| podSecurityContext | object | `{}` | The Pod Security Context |
| replicaCount | int | `1` | The number of replicas |
| resources | object | `{}` | Resource limitations for the pods |
| rosetta.envVars | object | `{}` | Environment variables to set on the pod |
| rosetta.graphqlURL | string | `"http://localhost:3085/graphql"` | GraphQL URL |
| rosetta.logLevel | string | `"Info"` | Log level |
| rosetta.maxDBPoolSize | int | `80` | Mina Archive Postgres Max Pool Size |
| rosetta.minaSuffix | string | `""` |  |
| rosetta.pgConnectionString | string | `"postgres://postgres:postgres@localhost:5432/postgres"` | Mina Archve Postgres Connection String |
| rosetta.pgDataInterval | int | `30` | Mina Archive Postgres Data Interval |
| securityContext | object | `{}` | The Security Context |
| service.port | int | `3087` | The service port |
| service.type | string | `"ClusterIP"` | The service type |
| serviceAccount.annotations | object | `{}` | Annotations to add to the service account |
| serviceAccount.create | bool | `true` | Specifies whether a service account should be created |
| serviceAccount.name | string | `""` | The name of the service account to use. |
| tolerations | list | `[]` | Tolerations |

