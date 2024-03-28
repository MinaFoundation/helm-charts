# `mina-payouts-data-provider` helm chart

A Helm chart to deploy [Mina Payouts Data Provider](https://github.com/jrwashburn/mina-payouts-data-provider).
Source: https://github.com/jrwashburn/mina-payouts-data-provider

> **Note** Currently MF does not have chart repository. To install this chart i.e. with helmfile you need to reffer to it following ways:
```console
# helmfile.yaml
<..>
releases:
  - name: mina-payouts-data-provider
    chart: git::https://git:accesstoken@github.com/MinaFoundation/helm-charts.git@mina-payouts-data-provider?ref=main
<..>
```

## Prerequisites

Before installing this Helm chart, you should have the following prerequisites:

 - Access to Kubernetes cluster
 - Helm installed on your local machine
 - Basic knowledge of Kubernetes and Helm
 - Access to https://github.com/MinaFoundation/helm-charts
 - Optional: helmfile to install this chart

## Installation

To install this Helm chart, easiest is create a helmfile.yaml with needed values and run:

```bash
$ helmfile template
$ helmfile apply
```

Or use helmfile only to generate resources and apply them with kubectl like so:

```bash
$ helmfile template | kubectl apply -f -
```

## Configuration

To get all available values in cloned `helm-charts` do:

```bash
$ helm show values ./mina-payouts-data-provider
```

The following table lists the configurable parameters of the `mina-payouts-data-provider` chart and its common default values.

### Settings

> **Note** This is only more notable list of values.

Parameter | Description | Default
--- | --- | ---
`nameOverride` | Override Release Name | ` `
`fullnameOverride` | Override Release and Chart Name | ` `
`serviceAccount.create` | Create or not Service Account | `true`
`serviceAccount.annotations` | Annotations for Service Account | `{}`
`serviceAccount.name` | If specified, name of the service account | ` `
--- | --- | ---
`replicaCount` | Number of Replicas | `1`
`image.repository` | Docker Respository | `673156464838.dkr.ecr.us-west-2.amazonaws.com/mina-payouts-data-provider`
`image.pullPolicy` | Image Pull Policy| `IfNotPresent`
`image.tag` | Tag | `2.0.2-552f1a5`
`image.imagePullSecrets` | Secret to pull Docker image | `[]`
`podAnnotations` | Pod Annotations | `{}`
`podSecurityContext` | Pod Security Context | `{}`
`securityContext` | Security Context | `{}`
`service.type` | Service Type | `ClusterIP`
`service.port` | Service Port | `80`
`ingress.enabled` | Enable Ingress | `false`
`ingress.className` | Ingress Class Name | ` `
`ingress.annotations` | Ingress Annotations | `{}`
`ingress.hosts` | Ingress Hosts | `[]`
`ingress.tls` | Ingress TLS | `[]`
`resources` | Resources allocated to the pods | `{}`
`livenessProbe` | Define livenessProbe | `{}`
`readinessProbe` | Define readinessProbe | `{}`
--- | --- | ---
`minaPayoutsDataProvider.numSlotsInEpoch` | Numbers of Slots in Epoch | `7140`
`minaPayoutsDataProvider.archiveDBRecencyThreshold` | Archive DB Recency Threshhold | `10`
`minaPayoutsDataProvider.ledgerUploadAPI.user` | Basic Auth username to connect to mina-payouts-data-provider API | `ledger-upload-api-user`
`minaPayoutsDataProvider.ledgerUploadAPI.password` | Basic Auth Password to connect to mina-payouts-data-provider API | `ledger-upload-api-password`
`minaPayoutsDataProvider.blockDBQuery.version` | Version of the Mina Archive database | `v1`
`minaPayoutsDataProvider.blockDBQuery.host` | Hostname of the Mina Archive database | `http://localhost`
`minaPayoutsDataProvider.blockDBQuery.port` | Port of the Mina Archive database | `5432`
`minaPayoutsDataProvider.blockDBQuery.user` | User of the Mina Archive database | `user`
`minaPayoutsDataProvider.blockDBQuery.password` | Password of the Mina Archive database | `password`
`minaPayoutsDataProvider.blockDBQuery.name` | Name of the Mina Archive database | `database`
`minaPayoutsDataProvider.blockDBQuery.ssl.enabled` | Enable SSL Connection to the Mina Archive database | `false`
`minaPayoutsDataProvider.blockDBQuery.ssl.rootCertificate` | Root Certificate required for SSL Connection to the Mina Archive database | ` `
`minaPayoutsDataProvider.ledgerDBQuery.host` | Hostname of the ledger database (Read) | `http://localhost`
`minaPayoutsDataProvider.ledgerDBQuery.port` | Port of the ledger database (Read) | `5432`
`minaPayoutsDataProvider.ledgerDBQuery.user` | User of the ledger database (Read) | `user`
`minaPayoutsDataProvider.ledgerDBQuery.password` | Password of the ledger database (Read) | `password`
`minaPayoutsDataProvider.ledgerDBQuery.name` | Name of the ledger database (Read) | `database`
`minaPayoutsDataProvider.ledgerDBQuery.ssl.enabled` | Enable SSL Connection to the ledger database (Read) | `false`
`minaPayoutsDataProvider.ledgerDBQuery.ssl.rootCertificate` | Root Certificate required for SSL Connection to the ledger database (Read) | ` `
`minaPayoutsDataProvider.ledgerDBCommand.host` | Hostname of the ledger database (Read/Write) | `http://localhost`
`minaPayoutsDataProvider.ledgerDBCommand.port` | Port of the ledger database (Read/Write) | `5432`
`minaPayoutsDataProvider.ledgerDBCommand.user` | User of the ledger database (Read/Write) | `user`
`minaPayoutsDataProvider.ledgerDBCommand.password` | Password of the ledger database (Read/Write) | `password`
`minaPayoutsDataProvider.ledgerDBCommand.name` | Name of the ledger database (Read/Write) | `database`
`minaPayoutsDataProvider.ledgerDBCommand.ssl.enabled` | Enable SSL Connection to the ledger database (Read/Write) | `false`
`minaPayoutsDataProvider.ledgerDBCommand.ssl.rootCertificate` | Root Certificate required for SSL Connection to the ledger database (Read/Write) | ` `
`minaPayoutsDataProvider.checkNodes` | List of Mina GraphQL Endpoints | `[]`
`minaPayoutsDataProvider.envVars` | Environment Variables to pass to the container | `{}`
--- | --- | ---
`nodeSelector` | Override Node Selector | `{}`
`tolerations` | Set tolerations | `[]`
`affinity` | Set affinity | `{}`
`postgresql.create` | Create a postgres database for the mina-payouts-data-provider api | `false`

## Uninstallation

To uninstall the Helm chart using helmfile, follow these steps:

```bash
$ helmfile destroy
```
or
```bash
$ helmfile template . | kubectl delete -f -
```
