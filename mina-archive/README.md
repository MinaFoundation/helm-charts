## Introduction

This chart bootstraps a Mina protocol Testnet archive node and associated Postgres database.

## Chart

Currently MF does not have chart repository. To install this chart i.e. with helmfile you need to reffer to it following ways:
 ```console
 #helmfile.yaml
 <..>
 releases:
   - name: mina-archive
     chart: git::ssh://git@github.com/MinaProtocol/mina-helm-charts-private.git@mina-archive?ref=main
     # or
     chart: git::https://git:accesstoken@github.com/MinaProtocol/mina-helm-charts-private.git@mina-daemon?ref=main
 <..>
 ```

## Subcharts

`mina-archive` uses only one subchart:
 - `postgresql` from https://charts.bitnami.com/bitnami
 -
However a working mina-archive setup also needs `mina-daemon` helm chart installed alongside found in https://github.com/minaProtocol/mina-helm-charts-private

## Configuration

The following table lists the configurable parameters of the `mina-archive` chart and its common default values.
To get all available values do:
```console
helm show values mina-archive`
```
### Required Settings

Parameter | Description
--- | ---
`archive.testnet` | Which `testnet` archive will be running on.
`archive.image` | container image to use for operating an archive node
`archive.remoteSchemaAuxFiles` | list of schema file download urls needed to bootstrap database.

### Optional Settings

Parameter | Description | Default
--- | --- | ---
`archive.postgresHost` | Postgres database host to store archival data | `see [default] values.yaml`
`archive.postgresUri` | Postgres [connection URI](https://www.postgresql.org/docs/current/libpq-connect.html#LIBPQ-CONNSTRING) to access postgres datastore instance | `see [default] values.yaml`
`archive.remoteSchemaFile` | archive database schema during initialization | `see [default] values.yaml`
`archive.metrics.enabled` | Whether to enable prometheus exporter for mina-archive | `false`
`archive.metrics.port` | Prometheus exporter port for mina-archive | `10002`

### Health probes

`mina-archive` health is determined checking it's rpc port liveness.

Parameter | Description | Default
--- | --- | ---
healthcheck.startup.periodSeconds | How often startupProbe is checked | `30`
healthcheck.startup.failureThreshold | # times startupProbe is allowed to fail | `5`
healthcheck.failureThreshold | # times liveness/readiness is allowed to fail | `5`
healthcheck.periodSeconds | How often liveness/readiness probes are checked | `5`
healthcheck.initialDelaySeconds | Time to wait before start checking liveness/readiness status | 30

### Postgresql Configuration

Please refer to official Postgresql by Bitnami [Documentation](https://github.com/bitnami/charts/blob/main/bitnami/postgresql/README.md#parameters)
