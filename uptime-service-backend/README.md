# Uptime service backend

A backend service for delegation program where participating nodes report stats about their activity.

## TL;DR

```console
git clone https://github.com/MinaFoundation/helm-charts
cd helm-charts/uptime-backend-service
helm install RELEASE_NAME ./ --namespace NAMESPACE
```

## Prerequisites

- Kubernetes 1.12+
- Helm 3.1.0

## Installing the Chart

To install the chart with the release name `RELEASE_NAME`:

```console
helm install RELEASE_NAME ./ --namespace NAMESPACE
```

The command deploys `uptime-service-backend` on the Kubernetes cluster in the default configuration. The [Parameters](#parameters) section lists the parameters that can be configured during installation.

## Uninstalling the Chart

To uninstall/delete the `RELEASE_NAME` deployment:

```console
helm delete RELEASE_NAME
```

The command removes all the Kubernetes components associated with the chart and deletes the release.

> **Note:** For `keyspace` storage backend helmchart sets default certificate located in `/database/cert/sf-class2-root.crt`. However this could be 

### Common parameters

| Name                           | Description                                            | Value           |
| ------------------------------ | ------------------------------------------------------ | --------------- |
| `deployment.image.repository`  | `uptime-service-backend` docker image url              | `673156464838.dkr.ecr.us-west-2.amazonaws.com/block-producers-uptime` |
| `deployment.image.tag`         | Docker image tag                                       | `1.0.0itn1` |
| `deployment.image.pullPolicy`  | Docker image pull policy                               | `IfNotPresent`  |
| `deployment.network`           | Testnet name                                           | `berkeley`      |
| `deployment.logLevel`          | Application log level                                  | `info`          |
| `replicas`                     | Amount of replicas to deploy                           | `1`             |
| `resources.request.memory`     | Memory requested for the application pod               | `256Mi`         |
| `resources.request.cpu`        | CPU resources requested for the application pod        | `500m`          |
| `resources.limit.memory`       | Maximum memory allowed for the application pod         | `512Mi`         |
| `resources.limit.cpu`          | Maximum CPU resources allowed for the application pod  | `1`             |
| `secret.gcpServiceAccount`     | Json Content of GCP Service Account                    | `""`            |
| `secret.keyspaceCert.override` | Whether to override default certificate                | `false`         |
| `secret.keyspaceCert.name`     | Name of certificate placed in `/uptime/certs`          | `""`            |
| `secret.keyspaceCert.content`  | Contents of certificate used by AWS Keyspaces          | `""`            |
| `service.type`                 | Kubernetes Service type                                | `ClusterIP`     |
| `service.port`                 | Kubernetes Service port                                | `8080`          |
| `ingress.enabled`              | Whether to enable ingress                              | `false`         |
| `ingress.className`            | Ingress class name                                     | `alb`           |
| `ingress.labels`               | Ingress Labels                                         | `{}`            |
| `ingress.annotations`          | Ingress Annotations                                    | `{}`            |
| `ingress.hosts`                | Ingress Hosts                                          | `[]`            |
| `serviceaccount.annotations`   | K8s Service Account Annotations                        | `{}`            |

## Application Parameters

### Google spreadsheet to read whitelist from

| Name                                       | Description           | Value |
| ------------------------------------------ | --------------------- | ----- |
| `deployment.whitelistConfig.spreadsheetId` | Google spreadsheet ID | `""`  |
| `deployment.whitelistConfig.sheet`         | Google sheet name     | `""`  |
| `deployment.whitelistConfig.column`        | Google document       | `""`  |

### AWS Account Parameters

| Name                                   | Description           | Value |
| -------------------------------------- | --------------------- | ----- |
| `deployment.awsConfig.accountId`       | AWS Account ID        | `""`  |
| `deployment.awsConfig.region`          | AWS Region            | `""`  |
| `deployment.awsConfig.accessKeyId`     | AWS Access Key ID     | `""`  |
| `deployment.awsConfig.secretAccessKey` | AWS Secret Access Key | `""`  |

### Storage Backend Parameters

> **Note:** Only one storage type should be configured at a time otherwise application will exit with an error.

| Name                                          | Description                                               | Value |
| --------------------------------------------- | --------------------------------------------------------- | ----- |
| `deployment.storage.type`                     | One of the 3 available types: `s3`,`keyspace` or `local`. | `""`  |
| `deployment.storage.s3.awsBucketNameSuffix`   | Buckets are named `awsAccountId`-`awsBucketNameSuffix`    | `""`  |
| `deployment.storage.keyspace.awsKeyspaceName` | Name of AWS Keyspace program should be using              | `""`  |
| `deployment.storage.local.path`               | Local path to store data                                  | `""`  |
