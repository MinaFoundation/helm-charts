# kyc-management-app

![Version: 0.1.0](https://img.shields.io/badge/Version-0.1.0-informational?style=flat-square) ![Type: application](https://img.shields.io/badge/Type-application-informational?style=flat-square) ![AppVersion: 1.16.0](https://img.shields.io/badge/AppVersion-1.16.0-informational?style=flat-square)

A Helm chart for Kubernetes

## Requirements

| Repository | Name | Version |
|------------|------|---------|
| https://charts.bitnami.com/bitnami | postgresql | * |

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
| databaseName | string | `"kyc"` |  |
| deploymentAnnotations | object | `{}` | Annotations to add to deployments |
| fullnameOverride | string | `""` | The full release name override |
| image.pullPolicy | string | `"IfNotPresent"` | The pullPolicy used when pulling the image |
| image.repository | string | `"673156464838.dkr.ecr.us-west-2.amazonaws.com/kyc-management-app"` | The repository of the image |
| image.tag | string | `"0.1.4"` | The tag of the image. Overrides the image tag whose default is the chart appVersion. |
| imagePullSecrets | list | `[]` | The secrets used to pull the image |
| ingress.annotations | object | `{}` | The Ingress Annotations |
| ingress.className | string | `""` | The Ingress Class Name to use |
| ingress.enabled | bool | `false` | Whether to create an Ingress |
| ingress.hosts | list | `[]` | The Ingress Hosts |
| ingress.tls | list | `[]` | The TLS configuration |
| kyc.api.authUrl | string | `"https://auth-sandbox.hakata.io"` |  |
| kyc.api.baseUrl | string | `"https://api-sandbox.hakata.io"` |  |
| kyc.api.clientId | string | `""` |  |
| kyc.api.clientSecret | string | `""` |  |
| kycManagementApp.app.envVars | object | `{}` | The ENV vars to set on the app container |
| kycManagementApp.app.port | int | `3000` | The port of the app service |
| kycManagementApp.dex.configBase64 | string | `""` | The configuration file for dex in base64 format |
| kycManagementApp.dex.envVars | object | `{}` | The ENV vars to set on the dex container |
| kycManagementApp.dex.port | int | `5556` | The port of the dex service |
| livenessProbe | string | `nil` | The Liveness Probe |
| nameOverride | string | `""` | The release name override |
| nodeSelector | object | `{}` | Node selector labels |
| podAnnotations | object | `{}` | Annotations to add to the pods |
| podLabels | object | `{}` | The labels to add to the pods |
| podSecurityContext | object | `{}` | The Pod Security Context |
| postgresql.auth.database | string | `"kyc"` | Database name |
| postgresql.auth.enablePostgresUser | bool | `false` | Enable the default postgres user |
| postgresql.auth.password | string | `"password"` | Password for the database |
| postgresql.auth.username | string | `"username"` | Username for the database |
| postgresql.enabled | bool | `true` | Enable local postgresql database server |
| postgresql.primary.persistence | object | `{"enabled":false,"size":"8Gi","storageClass":""}` | Extended configuration to configure postgresql server extendedConfiguration: |   max_connections=500   max_locks_per_transaction=100   max_pred_locks_per_relation=100   max_pred_locks_per_transaction=5000   max_wal_size=2048 |
| postgresql.primary.persistence.enabled | bool | `false` | Enable the persistence for the postgresql server |
| postgresql.primary.persistence.size | string | `"8Gi"` | Size of the postgresql server volume |
| postgresql.primary.persistence.storageClass | string | `""` | Storage class for the postgresql server volume |
| postgresql.primary.resourcesPreset | string | `"nano"` | Resources preset to set resource requests and limits |
| readinessProbe | string | `nil` | The Readiness Probe |
| replicaCount | int | `1` | The number of replicas |
| resources | object | `{}` | Resource limitations for the pods |
| securityContext | object | `{}` | The Security Context |
| service.port | int | `3000` | The port of the service |
| service.type | string | `"ClusterIP"` | The type of service to create |
| serviceAccount.annotations | object | `{}` | Annotations to add to the service account |
| serviceAccount.automount | bool | `true` | Automatically mount a ServiceAccount's API credentials? |
| serviceAccount.create | bool | `true` | Specifies whether a service account should be created |
| serviceAccount.name | string | `""` | If not set and create is true, a name is generated using the fullname template |
| tolerations | list | `[]` | Tolerations |
| volumeMounts | list | `[]` | Additional volumeMounts on the output Deployment definition. |
| volumes | list | `[]` | Additional volumes on the output Deployment definition. |

