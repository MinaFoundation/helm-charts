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

The following table lists the configurable parameters of the `mina-archive` chart and its default values.

### Required Settings

Parameter | Description
--- | ---
`archive.testnet` | Which `testnet` archive will be running on.
`archive.image` | container image to use for operating an archive node
`archive.remoteSchemaAuxFiles` | list of schema file download urls needed to bootstrap database.

### Optional Settings

Parameter | Description | Default
--- | --- | ---
`fullnameOverride` | Used to override release name. | `""`
`archive.postgresHost` | Postgres database host to store archival data | `see [default] values.yaml`
`archive.postgresUri` | Postgres [connection URI](https://www.postgresql.org/docs/current/libpq-connect.html#LIBPQ-CONNSTRING) to access postgres datastore instance | `see [default] values.yaml`
`archive.remoteSchemaFile` | archive database schema during initialization | `see [default] values.yaml`
`postgresql.primary.persistence.enabled` | whether to enable persistent storage for database data | `false`
`postgresql.primary.persistence.size` | PV size. | `8Gi`
`postgresql.primary.persistence.storageClass` | PV name postgresql should create PVC in. | `see [default] values.yaml`
`postgresql.auth.username` | Postgress database access username | `see [default] values.yaml`
`postgresql.auth.password` | Postgres database access password | `see [default] values.yaml`
`postgresql.auth.database` | Postgres database name | `see [default] values.yaml`
