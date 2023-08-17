# `mina-archive` helm chart

A helm chart to deploy Mina protocol archive node and Postgres database subchart.

> **Note** Currently MF does not have chart repository. To install this chart i.e. with helmfile you need to reffer to it following ways:

```console
# helmfile.yaml
<..>
releases:
  - name: mina-archive
    chart: git::ssh://git@github.com/MinaProtocol/mina-helm-charts-private.git@mina-archive?ref=main
<..>
```

## Subcharts

`mina-archive` uses only one subchart:
 - `postgresql` from https://charts.bitnami.com/bitnami

> **Note** `mina-archive` is filled by the mina daemon connecting to it. However charts were created separately for wider usability. These dependencies can/should be glued outside of chart using tools like `helmfile`.

helm chart installed alongside found in https://github.com/minaProtocol/mina-helm-charts-private

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
helm show values ./mina-archive
```

The following table lists the configurable parameters of the `mina-archive` chart and its common default values.

### Required Settings

Parameter | Description
--- | ---
`archive.testnet` | Which `testnet` archive will be running on.
`archive.image` | container image to use for operating an archive node
`archive.remoteSchemaAuxFiles` | list of schema file download urls needed to bootstrap database.
`archive.service.labels` | Custom Labels for the Archive Service | `{}`
`archive.service.annotations` | Custom Annotations for the Archive Service | `{}`

### Optional Settings

Parameter | Description | Default
--- | --- | ---
`archive.postgresHost` | Postgres database host to store archival data | `see [default] values.yaml`
`archive.postgresUri` | Postgres [connection URI](https://www.postgresql.org/docs/current/libpq-connect.html#LIBPQ-CONNSTRING) to access postgres datastore instance | `see [default] values.yaml`
`archive.remoteSchemaFile` | archive database schema during initialization | `see [default] values.yaml`
`archive.metrics.enabled` | Whether to enable prometheus exporter for mina-archive | `false`
`archive.metrics.port` | Prometheus exporter port for mina-archive | `10002`
`serviceAccount.annotations` | Allow role to assume this service account | `{}`
`podAnnotations` | Custom Annotations for the pod | `{}`

### Resource allocation

Parameter | Description | Default
--- | --- | ---
`resources.memoryRequest` | RAM to claim for mina archive container | "6.0Gi"
`resources.cpuRequest` | # of CPUs to claim for mina archive container | "3"
`resources.memoryLimit` | RAM limit for mina archive container | "8.0Gi"
`resources.cpuLimit` | # of CPUs limit for mina archive container | "4"

### Health probes

`mina-archive` health is determined checking it's rpc port liveness.

Parameter | Description | Default
--- | --- | ---
`healthcheck.startup.periodSeconds` | How often startupProbe is checked | `30`
`healthcheck.startup.failureThreshold` | # times startupProbe is allowed to fail | `5`
`healthcheck.failureThreshold` | # times liveness/readiness is allowed to fail | `5`
`healthcheck.periodSeconds` | How often liveness/readiness probes are checked | `5`
`healthcheck.initialDelaySeconds` | Time to wait before start checking liveness/readiness status | 30

### Postgresql Configuration

Please refer to official Postgresql by Bitnami [Documentation](https://github.com/bitnami/charts/blob/main/bitnami/postgresql/README.md#parameters)
