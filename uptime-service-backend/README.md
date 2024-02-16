# Uptime service backend

A backend service for delegation program where participating nodes report stats about their activity.


> **Note** Currently MF does not have chart repository. To install this chart i.e. with helmfile you need to reffer to it following ways:

```console
# helmfile.yaml
<..>
releases:
  - name: network_name
    chart: git::ssh://git@github.com/MinaFoundation/helm-charts.git@uptime-service-backend?ref=main
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

To install this Helm chart, the easiest is to create a helmfile.yaml with needed values and run:
```bash
$ helmfile template
$ helmfile apply
 ```

Or use helmfile only to generate resources and apply them with kubectl like so:

```bash
$ helmfile template | kubectl -f -
```

You can get some inspiration from helmfiles in `examples` folder.

Verify that the chart is deployed successfully:

```bash
helmfile status #although kubectl probably would give better insights.
```

## Configuration

To get all available values in cloned `helm-charts` do:

```bash
helm show values ./uptime-service-backend
```

The following table lists the configurable parameters of the `uptime-service-backend` chart and its common default values.

### Common parameters

| Name                           | Description                                            | Value           |
| ------------------------------ | ------------------------------------------------------ | --------------- |
| `image.repository`               | `uptime-service-backend` docker image url                | `673156464838.dkr.ecr.us-west-2.amazonaws.com/block-producers-uptime` |
| `image.tag`                      | Docker image tag                                       | `1.0.0itn1`       |
| `image.pullPolicy`               | Docker image pull policy                               | `IfNotPresent`    |
| `affinity`                       | Determines affinity https://kubernetes.io/docs/concepts/configuration/assign-pod-node/#affinity-and-anti-affinity | `{}` |
| `nodeSelector`                   | Override Node Selector                                 | `{}`              |
| `tolerations`                    | Set Tolerations                                        | `[]`              |
| `nameOverride`                   | Name override                                          | `""`              |
| `fullnameOverride`               | Fullname override                                      | `""`              |
| `podAnnotations`                 | Annotations to add to the pods                         | `{}`              |
| `podSecurityContext`             | Pod Security Context                                   | `{}`              |
| `securityContext`                | Security Context                                       | `{}`              |


### Secrets

| Name                           | Description                                            | Value           |
| ------------------------------ | ------------------------------------------------------ | --------------- |
| `secret.gcpServiceAccount`       | Json Content of GCP Service Account                    | `""`              |
| `secret.keyspaceCert.override`   | Whether to override default certificate                | `false`           |
| `secret.keyspaceCert.name`       | Name of certificate placed in `/uptime/certs`            | `""`              |
| `secret.keyspaceCert.content`    | Contents of certificate used by AWS Keyspaces          | `""`              |

### Service and Ingress

| Name                           | Description                                            | Value           |
| ------------------------------ | ------------------------------------------------------ | --------------- |
| `service.type`                   | Kubernetes Service type                                | `ClusterIP`       |
| `service.port`                   | Kubernetes Service port                                | `8080`            |
| `ingress.enabled`                | Whether to enable ingress                              | `false`           |
| `ingress.className`              | Ingress class name                                     | `alb`             |
| `ingress.labels`                 | Ingress Labels                                         | `{}`              |
| `ingress.annotations`            | Ingress Annotations                                    | `{}`              |
| `ingress.hosts`                  | Ingress Hosts                                          | `[]`              |

### Serviceaccount

| Name                           | Description                                            | Value           |
| ------------------------------ | ------------------------------------------------------ | --------------- |
| `serviceAccount.create`          | Specifies whether a Service Account should be created  | `true`            |
| `serviceaccount.annotations`     | K8s Service Account Annotations                        | `{}`              |

### Resources and scaling

| Name                           | Description                                            | Value           |
| ------------------------------ | ------------------------------------------------------ | --------------- |
| `replicaCount`                   | Amount of replicas to deploy                           | `1`               |
| `resources.request.memory`       | Memory requested for the application pod               | `256Mi`           |
| `resources.request.cpu`          | CPU resources requested for the application pod        | `500m`            |
| `resources.limit.memory`         | Maximum memory allowed for the application pod         | `512Mi`           |
| `resources.limit.cpu`            | Maximum CPU resources allowed for the application pod  | `1`               |
| `autoscaling.enabled`            | Autoscaling toggle                                     | `false`           |
| `autoscaling.minReplicas`        | Autoscaling minimum replicas                           | `1`               |
| `autoscaling.maxReplicas`        | Autoscaling maximum replicas                           | `10`              |
| `autoscaling.targetCPUUtilizationPercentage`| Autoscaling cpu utilization threshold in precentage| `80`       |
| `autoscaling.targetMemoryUtilizationPercentage`| Autoscaling memory utilization threshold in precentage| `80` |

### Application parameters

| Name                           | Description                                            | Value           |
| ------------------------------ | ------------------------------------------------------ | --------------- |
| `backend.network`                | Testnet name                                           | `""`              |
| `backend.requestsPerPkHourly`    | Number of requests accepted per hour                   | `1000`            |
| `backend.logLevel`               | Application log level                                  | `info`            |

### Google spreadsheet to read whitelist from

| Name                           | Description                                            | Value           |
| ------------------------------ | ------------------------------------------------------ | --------------- |
| `backend.whitelistConfig.enabled`| Whitelisting toggle. If enabled will configure other variables if not will omit| `false`|
| `backend.whitelistConfig.spreadsheetId`| Google spreadsheet ID                            | `""`              |
| `backend.whitelistConfig.sheet`  | Google sheet name                                      | `""`              |
| `backend.whitelistConfig.column` | Google document                                        | `""`              |

### AWS Account Parameters

| Name                           | Description                                            | Value           |
| ------------------------------ | ------------------------------------------------------ | --------------- |
| `backend.awsConfig.accountId`    | AWS Account ID                                         | `""`  |
| `backend.awsConfig.region`       | AWS Region                                             | `""`  |
| `backend.awsConfig.accessKeyId`  | AWS Access Key ID                                      | `""`  |
| `backend.awsConfig.secretAccessKey`| AWS Secret Access Key                                | `""`  |

### Storage Backend Parameters

> **Note:** Multiple storage types can be enabled.

| Name                           | Description                                            | Value           |
| ------------------------------ | ------------------------------------------------------ | --------------- |
| `backend.storage.type`           | One of the 3 available types: `s3`,`keyspace` or `local`.    | `""`              |
| `backend.storage.s3.awsBucketNameSuffix`| Buckets are named `awsAccountId`-`awsBucketNameSuffix`| `""`            |
| `backend.storage.keyspace.awsKeyspaceName`| Name of AWS Keyspace program should be using  | `""`              |
| `backend.storage.local.path`     | Local path to store data                               | `""`              |
