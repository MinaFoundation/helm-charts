# `block-producers-uptime-monitoring` helm chart

A Helm chart for the custom monitoring tools needed for Block Producers Uptime (further referred to as BPU)

> **Note** Currently MF does not have chart repository. To install this chart i.e. with helmfile you need to reffer to it following ways:
```
# helmfile.yaml
<..>
releases:
  - name: block-producers-uptime-monitoring
    chart: git::https://git:accesstoken@github.com/MinaProtocol/mina-helm-charts-private.git@block-producers-uptime-monitoring?ref=main
<..>
```

## Prerequisites

Before installing this Helm chart, you should have the following prerequisites:

 - Access to Kubernetes cluster
 - Helm installed on your local machine
 - Basic knowledge of Kubernetes and Helm
 - Access to https://github.com/minaProtocol/mina-helm-charts-private
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

You can get some inspiration from helmfiles in `examples` folder.

Verify that the chart is deployed successfully:

```bash
$ helmfile status #although kubectl probably would give better insights.
```

## Configuration

To get all available values in cloned `mina-helm-charts-private` do:

```bash
$ helm show values ./mina-daemon
```
The following table lists the configurable parameters of the `block-producers-uptime-monitoring` chart and its common default values.

### Required Settings

Parameter | Description
--- | ---
`deployment.image.repository` | image repository to pull the image from
`deployment.image.pullPolicy` | image pulling strategy
`deployment.image.tag` | tag of the image from the repository, usually containing commit hash, version, network and linux flavour
`deployment.replicaCount` | number of pods to deploy
`deployment.env.timeBefore` | environment variable that determines the time window of the application (time between current time and how much the user wants to look back)
`deployment.env.timeUnit` | the unit of measurement for the delta time (minutes,hours,seconds,days)

### Optional Settings

`deployment.affinity` | affinity for pod assignment (note: podAffinityPreset, podAntiAffinityPreset, and  nodeAffinityPreset will be ignored when it's set)
`deployment.podAffinityPreset` | pod affinity preset. Ignored if `affinity` is set. Allowed values: `soft` or `hard`
`deployment.podAntiAffinityPreset` | pod anti-affinity preset. Ignored if `affinity` is set. Allowed values: `soft` or `hard`
`deployment.nodeAffinityPreset` | affinity preset
`resources.memoryRequest` | requested memory for the application
`resources.cpuRequest` | requested cpu for the application
`resources.memoryLimit` | limit of the memory achieved by the application
`resources.cpuLimit` | limit of the cpu achieved by the application
`serviceaccount.annotations` | extra annotations for the service account

## Uninstallation

To uninstall the Helm chart using helmfile, follow these steps:

```bash
$ helmfile destroy
```
or
```bash
$ helmfile template . | kubectl delete -f -
```
