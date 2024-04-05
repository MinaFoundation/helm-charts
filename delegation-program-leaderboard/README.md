# `delegation-program-leaderboard` helm chart

A Helm chart to deploy Delegation Program Leaderboard.

> **Note** Currently MF does not have chart repository. To install this chart i.e. with helmfile you need to reffer to it following ways:
```console
# helmfile.yaml
<..>
releases:
  - name: mina-daemon
    chart: git::https://git:accesstoken@github.com/MinaFoundation/helm-charts.git@delegation-program-leaderboard?ref=main
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
$ helm show values ./delegation-program-leaderboard
```

The following table lists the configurable parameters of the `delegation-program-leaderboard` chart and its common default values.


### Optional Settings

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
`image.repository` | Docker Respository | `673156464838.dkr.ecr.us-west-2.amazonaws.com/delegation-program-leaderboard`
`image.pullPolicy` | Image Pull Policy| `IfNotPresent`
`image.tag` | Tag | `0.1.0`
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
--- | --- | ---
`leaderboard.envVars` | Environment Variables to pass to the container. See Application's README(or source) | `{}`
`leaderboard.dbHost` | Database Host | `localhost`
`leaderboard.dbPort` | Database Port | `5432`
`leaderboard.dbUser` | Database User | `postgres`
`leaderboard.dbPassword` | Database Password | `postgres`
`leaderboard.dbName` | Database Name | `postgres`
--- | --- | ---
`nodeSelector` | Override Node Selector | `{}`
`tolerations` | Set tolerations | `[]`
`affinity` | Set affinity | `{}`

## Uninstallation

To uninstall the Helm chart using helmfile, follow these steps:

```bash
$ helmfile destroy
```
or
```bash
$ helmfile template . | kubectl delete -f -
```
