# Mina Transactions Generator

A chart bootstraping a transactions generating script job.

## TL;DR

```console
git clone https://github.com/MinaFoundation/helm-charts
cd helm-charts/mina-transactions-generator
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

The command deploys `mina-transactions-generator` on the Kubernetes cluster in the default configuration. The [Parameters](#parameters) section lists the parameters that can be configured during installation.

## Uninstalling the Chart

To uninstall/delete the `RELEASE_NAME` deployment:

```console
helm delete RELEASE_NAME
```

The command removes all the Kubernetes components associated with the chart and deletes the release.

### Parameters

| Name                             | Description                                            | Value |
| -------------------------------- | ------------------------------------------------------ | ----- |
| `image.repository`               | `mina-transactions-generator` docker image url         | `673156464838.dkr.ecr.us-west-2.amazonaws.com/mina-transactions-generator` |
| `image.tag`                      | Docker image tag                                       | `0.1.2-5b82cae` |
| `image.pullPolicy`               | Docker image pull policy                               | `IfNotPresent` |
| `nameOverride`                   | Name override                                          | `""` |
| `fullnameOverride`               | Full name override                                     | `""` |
| `generator.minaGraphqlUrl`       | Graphql endpoint url to connect to.                    | `""` |
| `generator.senderPrivateKey`     | A private key of a sender                              | `""` |
| `generator.recipientWalletList`  | A list of wallet public keys to send transactions to.  | `[]` |
| `generator.transaction.type`     | Transaction type: `regular`, `zkApp` or `mixed`.       | `"regular"` |
| `generator.transaction.interval` | Time delay in ms between transactions.                 | `"5000"` |
| `generator.transaction.amount`   | Amount(per transaction) to send.                       | `"2"` |
| `generator.transaction.fee`      | Transaction fee.                                       | `"0.1"` |
| `resources.request.memory`       | Memory requested for the application pod               | `256Mi` |
| `resources.request.cpu`          | CPU resources requested for the application pod        | `500m` |
| `resources.limit.memory`         | Maximum memory allowed for the application pod         | `512Mi` |
| `resources.limit.cpu`            | Maximum CPU resources allowed for the application pod  | `1` |
| `serviceAccount.create`          | Specifies whether a service account should be created  | `true` |
| `serviceAccount.automount`       | Automatically mount a ServiceAccount's API credentials | `true` |
| `serviceAccount.annotations`     | Annotations to add to the service account              | `{}` |
