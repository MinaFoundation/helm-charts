# `on-chain-voting` helm chart

A Helm chart to deploy On Chain Voting.

> **Note** Currently MF does not have chart repository. To install this chart i.e. with helmfile you need to reffer to it following ways:
```console
# helmfile.yaml
<..>
releases:
  - name: mina-daemon
    chart: git::https://git:accesstoken@github.com/MinaFoundation/helm-charts.git@on-chain-voting?ref=main
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
$ helm show values ./on-chain-voting
```

The following table lists the configurable parameters of the `on-chain-voting` chart and its common default values.


### Optional Settings

> **Note** This is only more notable list of values.

Parameter | Description | Default
--- | --- | ---
`nameOverride` | Override Release Name | ` `
`fullnameOverride` | Override Release and Chart Name | ` `
`fullnameOverride` | Override Release and Chart Name | ` `
`serviceAccount.create` | Create or not Service Account | `true`
`serviceAccount.annotations` | Annotations for Service Account | `{}`
`serviceAccount.name` | If specified, name of the service account | ` `
--- | --- | ---
`web.replicaCount` | Number of Replicas | `1`
`web.image.repository` | Docker Respository | `673156464838.dkr.ecr.us-west-2.amazonaws.com/on-chain-voting`
`web.image.pullPolicy` | Image Pull Policy| `IfNotPresent`
`web.image.tag` | Tag | `web-0.1.0-39c837a`
`web.image.imagePullSecrets` | Secret to pull Docker image | `[]`
`web.podAnnotations` | Pod Annotations | `{}`
`web.podSecurityContext` | Pod Security Context | `{}`
`web.securityContext` | Security Context | `{}`
`web.service.type` | Service Type | `ClusterIP`
`web.service.port` | Service Port | `3000`
`web.ingress.enabled` | Enable Ingress | `false`
`web.ingress.className` | Ingress Class Name | ` `
`web.ingress.annotations` | Ingress Annotations | `{}`
`web.ingress.hosts` | Ingress Hosts | `[]`
`web.ingress.tls` | Ingress TLS | `[]`
`web.resources` | Resources allocated to the pods | `{}`
`web.extraEnvVars` | Additional Environment Variables | `{}`
`web.nodeSelector` | Override Node Selector | `{}`
`web.tolerations` | Set tolerations | `[]`
`web.affinity` | Set affinity | `{}`
--- | --- | ---
`server.replicaCount` | Number of Replicas | `1`
`server.image.repository` | Docker Respository | `673156464838.dkr.ecr.us-west-2.amazonaws.com/on-chain-voting`
`server.image.pullPolicy` | Image Pull Policy| `IfNotPresent`
`server.image.tag` | Tag | `server-0.1.0-39c837a`
`server.image.imagePullSecrets` | Secret to pull Docker image | `[]`
`server.podAnnotations` | Pod Annotations | `{}`
`server.podSecurityContext` | Pod Security Context | `{}`
`server.securityContext` | Security Context | `{}`
`server.service.type` | Service Type | `ClusterIP`
`server.service.port` | Service Port | `80`
`server.resources` | Resources allocated to the pods | `{}`
`server.extraEnvVars` | Additional Environment Variables | `{}`
`server.nodeSelector` | Override Node Selector | `{}`
`server.tolerations` | Set tolerations | `[]`
`server.affinity` | Set affinity | `{}`

## Uninstallation

To uninstall the Helm chart using helmfile, follow these steps:

```bash
$ helmfile destroy
```
or
```bash
$ helmfile template . | kubectl delete -f -
```
