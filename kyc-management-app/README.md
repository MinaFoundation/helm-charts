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
| affinity | object | `{}` | Affinity for pod assignment |
| autoscaling.enabled | bool | `false` | Enable autoscaling for the deployment |
| autoscaling.maxReplicas | int | `100` | Maximum number of pods |
| autoscaling.minReplicas | int | `1` | Minimum number of pods |
| autoscaling.targetCPUUtilizationPercentage | int | `80` | Target CPU utilization percentage |
| deploymentAnnotations | object | `{}` | Annotations to add to deployments |
| envVars | object | `{}` | Environment variables to set on the pod |
| fullnameOverride | string | `""` | Full name override |
| image.pullPolicy | string | `"IfNotPresent"` | The image pull policy |
| image.repository | string | `"673156464838.dkr.ecr.us-west-2.amazonaws.com/kyc-management-app"` | The image repository |
| image.tag | string | `"0.1.25"` | Overrides the image tag whose default is the chart appVersion. |
| imagePullSecrets | list | `[]` | The secrets used to pull the image |
| ingress.annotations | object | `{}` | The Ingress Annotations |
| ingress.className | string | `""` | The Ingress Class Name to use |
| ingress.enabled | bool | `false` | Whether to create an Ingress |
| ingress.hosts | list | `[{"host":"chart-example.local","paths":[{"path":"/","pathType":"ImplementationSpecific"}]}]` | The Ingress Hosts |
| ingress.tls | list | `[]` | The TLS configuration |
| livenessProbe | object | `{"httpGet":{"path":"/version","port":"http"}}` | The liveness probes |
| nameOverride | string | `""` | Name override |
| nodeSelector | object | `{}` | Node labels for pod assignment |
| podAnnotations | object | `{}` | Annotations to add to the pods |
| podLabels | object | `{}` | Label to add to the pods |
| podSecurityContext | object | `{}` | The Pod Security Context |
| postgresUri | string | `nil` | The postgresql uri if the postgresql chart is disabled |
| postgresql.auth.database | string | `"kyc"` | Database name |
| postgresql.auth.enablePostgresUser | bool | `false` | Enable the default postgres user |
| postgresql.auth.password | string | `"password"` | Password for the database |
| postgresql.auth.username | string | `"username"` | Username for the database |
| postgresql.enabled | bool | `true` | Enable local postgresql database server |
| postgresql.primary.persistence | object | `{"enabled":true,"size":"1Gi","storageClass":"ebs-gp3-encrypted"}` | Extended configuration to configure postgresql server extendedConfiguration: |   max_connections=500   max_locks_per_transaction=100   max_pred_locks_per_relation=100   max_pred_locks_per_transaction=5000   max_wal_size=2048 |
| postgresql.primary.persistence.enabled | bool | `true` | Enable the persistence for the postgresql server |
| postgresql.primary.persistence.size | string | `"1Gi"` | Size of the postgresql server volume |
| postgresql.primary.persistence.storageClass | string | `"ebs-gp3-encrypted"` | Storage class for the postgresql server volume |
| postgresql.primary.resourcesPreset | string | `"nano"` | Resources preset to set resource requests and limits |
| readinessProbe | object | `{"httpGet":{"path":"/version","port":"http"}}` | The readiness probes |
| replicaCount | int | `1` | The number of replicas |
| resources | object | `{}` | Resources |
| securityContext | object | `{}` | The Security Context |
| service.port | int | `3000` | The service port |
| service.type | string | `"ClusterIP"` | The service type |
| serviceAccount.annotations | object | `{}` | Annotations to add to the service account |
| serviceAccount.automount | bool | `true` | Automatically mount a ServiceAccount's API credentials? |
| serviceAccount.create | bool | `true` | Specifies whether a service account should be created |
| serviceAccount.name | string | `""` | If not set and create is true, a name is generated using the fullname template |
| tolerations | list | `[]` | Tolerations for pod assignment |
| volumeMounts | list | `[]` | Additional volumeMounts on the output Deployment definition. |
| volumes | list | `[]` | Additional volumes on the output Deployment definition. |

