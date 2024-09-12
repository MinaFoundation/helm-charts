# mina-payout-reports

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
| fullnameOverride | string | `""` | The full release name override |
| nameOverride | string | `""` | The release name override |
| payoutReportsApi.affinity | object | `{}` | Affinity rules |
| payoutReportsApi.archiveDB.host | string | `"localhost"` | Mina Archive Database Host |
| payoutReportsApi.archiveDB.name | string | `"postgres"` | Mina Archive Database Name |
| payoutReportsApi.archiveDB.password | string | `"postgres"` | Mina Archive Database Password |
| payoutReportsApi.archiveDB.port | string | `"5432"` | Mina Archive Database Port |
| payoutReportsApi.archiveDB.user | string | `"postgres"` | Mina Archive Database User |
| payoutReportsApi.aws.accessKeyID | string | `""` | AWS access key ID(leave empty to assume role) |
| payoutReportsApi.aws.region | string | `"us-west-2"` | AWS Region |
| payoutReportsApi.aws.secretAccessKey | string | `""` | AWS access key secret(leave empty to assume role) |
| payoutReportsApi.contactDetailsSpreadsheetName | string | `""` | Google spreadsheet containing contact details |
| payoutReportsApi.delegationDB.host | string | `"localhost"` | Delegation Program Database Host |
| payoutReportsApi.delegationDB.name | string | `"delegation_program"` | Delegation Program Database Name |
| payoutReportsApi.delegationDB.password | string | `"postgres"` | Delegation Program Database Password |
| payoutReportsApi.delegationDB.port | string | `"5432"` | Delegation Program Database Port |
| payoutReportsApi.delegationDB.user | string | `"postgres"` | Delegation Program Database User |
| payoutReportsApi.extraEnvVars | object | `{}` | Extra Environment Variables |
| payoutReportsApi.frontendPublicUrl | string | `"localhost:3000"` | Payout reports frontend public url accessible from the client |
| payoutReportsApi.gcpServiceAccount | string | `""` | GCP ServiceAccount json data to create a secret from |
| payoutReportsApi.image.pullPolicy | string | `"IfNotPresent"` | The pullPolicy used when pulling the image |
| payoutReportsApi.image.repository | string | `"673156464838.dkr.ecr.us-west-2.amazonaws.com/mina-payout-reports"` | The repository of the image |
| payoutReportsApi.image.tag | string | `""` | The tag of the image |
| payoutReportsApi.imagePullSecrets | list | `[]` | The secrets used to pull the image |
| payoutReportsApi.ingress.annotations | object | `{}` | The Ingress Annotations |
| payoutReportsApi.ingress.className | string | `""` | The Ingress Class Name to use |
| payoutReportsApi.ingress.enabled | bool | `false` | Whether to create a backend Ingress |
| payoutReportsApi.ingress.hosts | list | `[]` | The Ingress Hosts |
| payoutReportsApi.ingress.tls | list | `[]` | The TLS configuration |
| payoutReportsApi.livenessProbe | object | `{}` | Liveness check configuration |
| payoutReportsApi.nodeSelector | object | `{}` | Node selector labels |
| payoutReportsApi.payoutsDB.host | string | `"localhost"` | Delegation Program Payouts Database Host |
| payoutReportsApi.payoutsDB.name | string | `"postgres"` | Delegation Program Payouts Database Name |
| payoutReportsApi.payoutsDB.password | string | `"postgres"` | Delegation Program Payouts Database Password |
| payoutReportsApi.payoutsDB.port | string | `"5432"` | Delegation Program Payouts Database Port |
| payoutReportsApi.payoutsDB.user | string | `"postgres"` | Delegation Program Payouts Database User |
| payoutReportsApi.podAnnotations | object | `{}` | Annotations to add to the pods |
| payoutReportsApi.podSecurityContext | object | `{}` | The Pod Security Context |
| payoutReportsApi.readinessProbe | object | `{}` | Readiness check configuration |
| payoutReportsApi.replicaCount | int | `1` | The number of replicas |
| payoutReportsApi.resources | object | `{}` | Resource limitations for the pods |
| payoutReportsApi.s3Bucket | string | `""` | S3 bucket where to store reports |
| payoutReportsApi.securityContext | object | `{}` | The Security Context |
| payoutReportsApi.sendgridToken | string | `""` | A token to use SendGrid email API |
| payoutReportsApi.service.port | int | `5000` | The port of the service |
| payoutReportsApi.service.type | string | `"ClusterIP"` | The type of service to create |
| payoutReportsApi.stakingLedgersBucket | string | `""` | Staking ledgers bucket name(AWS S3) |
| payoutReportsApi.tolerations | list | `[]` | Tolerations |
| payoutReportsApi.walletMappingSpreadsheetTab | string | `""` | Google's public spreadsheet sheet(tab) name  |
| payoutReportsApi.walletMappingSpreadsheetUrl | string | `""` | Google's public spreadsheet url containing wallet mappings |
| payoutReportsWeb.affinity | object | `{}` | Affinity rules |
| payoutReportsWeb.backendPublicUrl | string | `"localhost:5000"` | Payout reports backend public url accessible from the client |
| payoutReportsWeb.extraEnvVars | list | `[]` | Additional list of Environment Variables |
| payoutReportsWeb.image.pullPolicy | string | `"IfNotPresent"` | The pullPolicy used when pulling the image |
| payoutReportsWeb.image.repository | string | `"673156464838.dkr.ecr.us-west-2.amazonaws.com/mina-payout-reports"` | The repository of the image |
| payoutReportsWeb.image.tag | string | `""` | The tag of the image |
| payoutReportsWeb.imagePullSecrets | list | `[]` | The secrets used to pull the image |
| payoutReportsWeb.ingress.annotations | object | `{}` | The Ingress Annotations |
| payoutReportsWeb.ingress.className | string | `""` | The Ingress Class Name to use |
| payoutReportsWeb.ingress.enabled | bool | `false` | Whether to create a frontend Ingress |
| payoutReportsWeb.ingress.hosts | list | `[]` | The Ingress Hosts |
| payoutReportsWeb.ingress.tls | list | `[]` | The TLS configuration |
| payoutReportsWeb.livenessProbe | object | `{}` | Liveness check configuration |
| payoutReportsWeb.nodeSelector | object | `{}` | Node selector labels |
| payoutReportsWeb.podAnnotations | object | `{}` | Annotations to add to the pods |
| payoutReportsWeb.podSecurityContext | object | `{}` | The Pod Security Context |
| payoutReportsWeb.readinessProbe | object | `{}` | Readiness check configuration |
| payoutReportsWeb.replicaCount | int | `1` | The number of replicas |
| payoutReportsWeb.resources | object | `{}` | Resource limitations for the pods |
| payoutReportsWeb.securityContext | object | `{}` | The Security Context |
| payoutReportsWeb.service.port | int | `3000` | The port of the service |
| payoutReportsWeb.service.type | string | `"ClusterIP"` | The type of service to create |
| payoutReportsWeb.tolerations | list | `[]` | Tolerations |
| serviceAccount.annotations | object | `{}` | Annotations to add to the service account |
| serviceAccount.create | bool | `true` | Specifies whether a service account should be created |
| serviceAccount.name | string | `""` | If not set and create is true, a name is generated using the fullname template |

