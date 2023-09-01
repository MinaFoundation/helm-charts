# `node-stats-collector` helm chart
A helm chart to deploy node-stats-collector.

> **Note** Currently MF does not have chart repository. To install this chart i.e. with helmfile you need to reffer to it following ways:

```console
# helmfile.yaml
<..>
releases:
  - name: partner1
    chart: git::ssh://git@github.com/MinaProtocol/mina-helm-charts-private.git@node-stats-collector?ref=main
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

To get all available values in cloned `mina-helm-charts-private` do:

```bash
helm show values ./node-stats-collector
```

The following table lists the configurable parameters of the `node-stats-collector` chart and its common default values.

### Application Settings

Parameter | Description | Default
--- | --- | ---
`nodestats.opensearchUrl` | Opensearch domain internal endpoint where application should send stats. | ""
`nodestats.partner` | Partner who will report node stats to application. | ""

### Resource allocation

Parameter | Description | Default
--- | --- | ---
`resources` | Resources to allocate for helm chart pods. | {}

### Image
--- | --- | ---
`image.repository` | Image repository url | 673156464838.dkr.ecr.us-west-2.amazonaws.com/node-stats-collector
`image.pullPolicy` | Image pull policy | IfNotPresent
`image.tag` | Image tag | "2023.09"

### Health probes

Health is reported by json response querying `/health` endpoint.

### Ingress

Ingress is configurable however details are out of scope of this README.

### Other values

Other configurable values(like `resources`) are transparent and aren't specific to this helm chart. See running examples in our environment.
