# kyc-management-app

![Version: 0.3.0](https://img.shields.io/badge/Version-0.3.0-informational?style=flat-square) ![Type: application](https://img.shields.io/badge/Type-application-informational?style=flat-square) ![AppVersion: 1.16.0](https://img.shields.io/badge/AppVersion-1.16.0-informational?style=flat-square)

A Helm chart for Kubernetes

## Requirements

| Repository | Name | Version |
|------------|------|---------|
| https://charts.bitnami.com/bitnami | postgresql | 15.5.26 |

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
| dashboard.deploymentAnnotations | object | `{}` | Annotations to add to deployments |
| dashboard.envVars | object | `{}` |  |
| dashboard.livenessProbe | object | `{"httpGet":{"path":"/dashboard/version","port":"http"}}` | The liveness probes |
| dashboard.podAnnotations | object | `{}` | Annotations to add to the pods |
| dashboard.podLabels | object | `{}` | Label to add to the pods |
| dashboard.readinessProbe | object | `{"httpGet":{"path":"/dashboard/health","port":"http"},"timeoutSeconds":5}` | The readiness probes |
| dashboard.replicaCount | int | `0` | The number of replicas |
| envVars | object | `{}` | Environment variables to set on the pod |
| fullnameOverride | string | `""` | Full name override |
| gcpServiceAccount | string | `""` | GCP service account json |
| hook.deploymentAnnotations | object | `{}` | Annotations to add to deployments |
| hook.envVars | object | `{}` |  |
| hook.livenessProbe | object | `{"httpGet":{"path":"/hook/version","port":"http"}}` | The liveness probes |
| hook.podAnnotations | object | `{}` | Annotations to add to the pods |
| hook.podLabels | object | `{}` | Label to add to the pods |
| hook.readinessProbe | object | `{"httpGet":{"path":"/hook/health","port":"http"},"timeoutSeconds":5}` | The readiness probes |
| hook.replicaCount | int | `0` | The number of replicas |
| image.pullPolicy | string | `"IfNotPresent"` | The image pull policy |
| image.repository | string | `"673156464838.dkr.ecr.us-west-2.amazonaws.com/kyc-management-app"` | The image repository |
| image.tag | string | `"1.0.0"` | Overrides the image tag whose default is the chart appVersion. |
| imagePullSecrets | list | `[]` | The secrets used to pull the image |
| ingress.annotations | object | `{}` | The Ingress Annotations |
| ingress.className | string | `""` | The Ingress Class Name to use |
| ingress.enabled | bool | `false` | Whether to create an Ingress |
| ingress.hosts | list | `[{"host":"chart-example.local","paths":[{"path":"/","pathType":"ImplementationSpecific"}]}]` | The Ingress Hosts |
| ingress.tls | list | `[]` | The TLS configuration |
| lifecycle | object | `{"preStop":{"exec":{"command":["sh","-c","sleep 15 && kill -SIGQUIT 1"]}}}` | Lifecycle hooks |
| nameOverride | string | `""` | Name override |
| nodeSelector | object | `{}` | Node labels for pod assignment |
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
| resources | object | `{}` | Resources |
| securityContext | object | `{}` | The Security Context |
| service.port | int | `3000` | The service port |
| service.type | string | `"ClusterIP"` | The service type |
| serviceAccount.annotations | object | `{}` | Annotations to add to the service account |
| serviceAccount.automount | bool | `true` | Automatically mount a ServiceAccount's API credentials? |
| serviceAccount.create | bool | `true` | Specifies whether a service account should be created |
| serviceAccount.name | string | `""` | The name of the service account to use. |
| tolerations | list | `[]` | Tolerations for pod assignment |
| volumeMounts | list | `[]` | Additional volumeMounts on the output Deployment definition. |
| volumes | list | `[]` | Additional volumes on the output Deployment definition. |
| web.deploymentAnnotations | object | `{}` | Annotations to add to deployments |
| web.envVars | object | `{}` |  |
| web.livenessProbe | object | `{"httpGet":{"path":"/version","port":"http"}}` | The liveness probes |
| web.podAnnotations | object | `{}` | Annotations to add to the pods |
| web.podLabels | object | `{}` | Label to add to the pods |
| web.readinessProbe | object | `{"httpGet":{"path":"/health","port":"http"},"timeoutSeconds":5}` | The readiness probes |
| web.replicaCount | int | `0` | The number of replicas |

